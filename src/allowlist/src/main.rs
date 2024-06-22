use axum::{
    debug_handler,
    extract::State,
    http::StatusCode,
    routing::{get, post},
    Json, Router,
};
use bb8::Pool;
use bb8_redis::RedisConnectionManager;
use move_core_types::account_address::AccountAddress;
use redis::AsyncCommands;
use serde::{Deserialize, Serialize};

#[tokio::main]
async fn main() {
    // Get a Redis connection, verify a key can be set and retrieved.
    let manager = RedisConnectionManager::new("redis://localhost").unwrap();
    let pool = bb8::Pool::builder().build(manager).await.unwrap();
    {
        let mut conn = pool.get().await.unwrap();
        conn.set::<&str, &str, ()>("foo", "bar").await.unwrap();
        let result: String = conn.get("foo").await.unwrap();
        assert_eq!(result, "bar");
    }

    let app = Router::new()
        .route("/", get(is_allowed).post(add_to_allowlist))
        .with_state(pool);

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

#[debug_handler]
async fn is_allowed(
    State(pool): State<Pool<RedisConnectionManager>>,
    Json(payload): Json<RequestAddress>,
) -> (StatusCode, Json<RequestResult>) {
    if let Ok(account_address) = AccountAddress::try_from(payload.address.clone()) {
        let parsed_address = account_address.to_hex_literal();
        let mut result = RequestResult {
            requested_address: payload.address,
            parsed_address: Some(parsed_address.clone()),
            result: "Not allowed".to_string(),
        };
        match pool.get().await {
            Ok(mut conn) => {
                match conn
                    .sismember::<&str, &str, i32>("allowlist", &parsed_address)
                    .await
                {
                    Ok(lookup_result) => {
                        if lookup_result == 1 {
                            result.result = "Allowed".to_string();
                        };
                        (StatusCode::OK, Json(result))
                    }
                    Err(e) => {
                        // Lookup issue.
                        result.result = format!("Lookup issue: {}", e);
                        (StatusCode::INTERNAL_SERVER_ERROR, Json(result))
                    }
                }
            }
            Err(e) => {
                // Could not connect to Redis.
                result.result = format!("Redis connection issue: {}", e);
                (StatusCode::INTERNAL_SERVER_ERROR, Json(result))
            }
        }
    } else {
        invalid_address(payload.address)
    }
}

async fn add_to_allowlist(
    State(pool): State<Pool<RedisConnectionManager>>,
    Json(payload): Json<RequestAddress>,
) -> (StatusCode, Json<RequestResult>) {
    if let Ok(account_address) = AccountAddress::try_from(payload.address.clone()) {
        let parsed_address = account_address.to_hex_literal();
        let mut result = RequestResult {
            requested_address: payload.address,
            parsed_address: Some(parsed_address.clone()),
            result: "Added to allowlist".to_string(),
        };
        match pool.get().await {
            Ok(mut conn) => {
                match conn
                    .sadd::<&str, &str, i32>("allowlist", &parsed_address)
                    .await
                {
                    Ok(add_result) => {
                        if add_result == 0 {
                            result.result = "Already allowed".to_string();
                        };
                        (StatusCode::OK, Json(result))
                    }
                    Err(e) => {
                        // Add member issue.
                        result.result = format!("Add member issue: {}", e);
                        (StatusCode::INTERNAL_SERVER_ERROR, Json(result))
                    }
                }
            }
            Err(e) => {
                // Could not connect to Redis.
                result.result = format!("Redis connection issue: {}", e);
                (StatusCode::INTERNAL_SERVER_ERROR, Json(result))
            }
        }
    } else {
        invalid_address(payload.address)
    }
}

fn invalid_address(address: String) -> (StatusCode, Json<RequestResult>) {
    (
        StatusCode::BAD_REQUEST,
        Json(RequestResult {
            requested_address: address,
            parsed_address: None,
            result: "Could not parse address".to_string(),
        }),
    )
}

#[derive(Deserialize)]
struct RequestAddress {
    address: String,
}

#[derive(Serialize)]
struct RequestResult {
    requested_address: String,
    parsed_address: Option<String>,
    result: String,
}
