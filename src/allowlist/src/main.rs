// cspell:word sadd
// cspell:word sismember

use axum::{extract::State, http::StatusCode, routing::get, Json, Router};
use bb8::Pool;
use bb8_redis::RedisConnectionManager;
use move_core_types::account_address::AccountAddress;
use redis::AsyncCommands;
use serde::{Deserialize, Serialize};

/// The name of the Redis set that contains the allowlist.
const SET_NAME: &str = "allowlist";

/// The value that indicates a member is in the set.
const IN_SET: i32 = 1;

/// The value that indicates a member was not added to the set, since it was already present.
const NOT_ADDED: i32 = 0;

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

async fn is_allowed(
    State(pool): State<Pool<RedisConnectionManager>>,
    Json(payload): Json<RequestAddress>,
) -> (StatusCode, Json<RequestResult>) {
    if let Ok(account_address) = AccountAddress::try_from(payload.address.clone()) {
        let mut result =
            default_result(payload.address, account_address, "Not allowed".to_string());
        match pool.get().await {
            Ok(mut conn) => {
                match conn
                    .sismember::<&str, &str, i32>(SET_NAME, &result.parsed_address.clone().unwrap())
                    .await
                {
                    Ok(lookup_result) => {
                        if lookup_result == IN_SET {
                            result.result = "Allowed".to_string();
                        };
                        (StatusCode::OK, Json(result))
                    }
                    Err(e) => internal_server_error(result, "Lookup issue", e),
                }
            }
            Err(e) => redis_connection_error(result, e),
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
        let mut result = default_result(
            payload.address,
            account_address,
            "Added to allowlist".to_string(),
        );
        match pool.get().await {
            Ok(mut conn) => {
                match conn
                    .sadd::<&str, &str, i32>(SET_NAME, &result.parsed_address.clone().unwrap())
                    .await
                {
                    Ok(add_result) => {
                        if add_result == NOT_ADDED {
                            result.result = "Already allowed".to_string();
                        };
                        (StatusCode::OK, Json(result))
                    }
                    Err(e) => internal_server_error(result, "Add member issue", e),
                }
            }
            Err(e) => redis_connection_error(result, e),
        }
    } else {
        invalid_address(payload.address)
    }
}

fn default_result(
    payload_address: String,
    account_address: AccountAddress,
    result_message: String,
) -> RequestResult {
    RequestResult {
        requested_address: payload_address,
        parsed_address: Some(account_address.to_hex_literal()),
        result: result_message,
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

fn internal_server_error(
    mut request_result: RequestResult,
    message_header: &str,
    e: redis::RedisError,
) -> (StatusCode, Json<RequestResult>) {
    request_result.result = format!("{}: {}", message_header, e);
    (StatusCode::INTERNAL_SERVER_ERROR, Json(request_result))
}

fn redis_connection_error(
    mut request_result: RequestResult,
    e: bb8::RunError<redis::RedisError>,
) -> (StatusCode, Json<RequestResult>) {
    request_result.result = format!("Redis connection issue: {}", e);
    (StatusCode::INTERNAL_SERVER_ERROR, Json(request_result))
}
