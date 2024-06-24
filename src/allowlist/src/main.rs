// cspell:word sadd
// cspell:word sismember

use axum::{
    extract::{Path, State},
    http::StatusCode,
    routing::get,
    Json, Router,
};
use bb8::Pool;
use bb8_redis::RedisConnectionManager;
use move_core_types::account_address::AccountAddress;
use redis::AsyncCommands;
use serde::Serialize;

/// The name of the Redis set that contains the allowlist.
const SET_NAME: &str = "allowlist";

/// The value that indicates a member is not in the set.
const NOT_IN_SET: i32 = 0;

/// The value that indicates a member was not added to the set, since it was already present.
const NOT_ADDED: i32 = 0;

type CodedSummary = (StatusCode, Json<RequestSummary>);

type RequestResult = Result<CodedSummary, CodedSummary>;

#[derive(Clone, Serialize)]
struct RequestSummary {
    request_address: String,
    parsed_address: Option<String>,
    is_allowed: Option<bool>,
    message: String,
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
        .route("/:request_address", get(is_allowed).post(add_to_allowlist))
        .with_state(pool);

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn is_allowed(
    State(pool): State<Pool<RedisConnectionManager>>,
    Path(request_address): Path<String>,
) -> RequestResult {
    let (mut result_summary, parsed_address) =
        default_result_summary_with_parsed_address(request_address.clone(), "Found in allowlist")?;
    let mut connection = pool
        .get()
        .await
        .map_err(|e| redis_connection_error(result_summary.clone(), e))?;
    if connection
        .sismember::<&str, &str, i32>(SET_NAME, &parsed_address)
        .await
        .map_err(|e| internal_server_error(result_summary.clone(), "Add member issue", e))?
        == NOT_IN_SET
    {
        result_summary.is_allowed = Some(false);
        result_summary.message = "Not found in allowlist".to_string();
    };
    Ok((StatusCode::OK, Json(result_summary)))
}

async fn add_to_allowlist(
    State(pool): State<Pool<RedisConnectionManager>>,
    Path(request_address): Path<String>,
) -> RequestResult {
    let (mut result_summary, parsed_address) =
        default_result_summary_with_parsed_address(request_address.clone(), "Added to allowlist")?;
    let mut connection = pool
        .get()
        .await
        .map_err(|e| redis_connection_error(result_summary.clone(), e))?;
    if connection
        .sadd::<&str, &str, i32>(SET_NAME, &parsed_address)
        .await
        .map_err(|e| internal_server_error(result_summary.clone(), "Add member issue", e))?
        == NOT_ADDED
    {
        result_summary.message = "Already allowed".to_string();
    };
    Ok((StatusCode::OK, Json(result_summary)))
}

fn default_result_summary_with_parsed_address(
    request_address: String,
    result_message: &str,
) -> Result<(RequestSummary, String), CodedSummary> {
    let account_address = AccountAddress::try_from(request_address.clone()).map_err(|_| {
        (
            StatusCode::BAD_REQUEST,
            Json(RequestSummary {
                request_address: request_address.clone(),
                parsed_address: None,
                is_allowed: None,
                message: "Could not parse address".to_string(),
            }),
        )
    })?;
    let parsed_address = account_address.to_hex_literal();
    Ok((
        RequestSummary {
            request_address,
            parsed_address: Some(parsed_address.clone()),
            is_allowed: Some(true),
            message: result_message.to_string(),
        },
        parsed_address,
    ))
}

fn internal_server_error(
    mut request_summary: RequestSummary,
    message_header: &str,
    e: redis::RedisError,
) -> CodedSummary {
    request_summary.message = format!("{}: {}", message_header, e);
    (StatusCode::INTERNAL_SERVER_ERROR, Json(request_summary))
}

fn redis_connection_error(
    mut request_summary: RequestSummary,
    e: bb8::RunError<redis::RedisError>,
) -> CodedSummary {
    request_summary.message = format!("Redis connection issue: {}", e);
    (StatusCode::INTERNAL_SERVER_ERROR, Json(request_summary))
}
