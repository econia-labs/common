// cspell:word sadd
// cspell:word sismember

use axum::{
    async_trait,
    extract::{rejection::PathRejection, FromRef, FromRequestParts, Path},
    http::{request::Parts, StatusCode},
    routing::get,
    Json, Router,
};
use bb8::{Pool, PooledConnection, RunError};
use bb8_redis::RedisConnectionManager;
use move_core_types::account_address::{AccountAddress, AccountAddressParseError};
use redis::{AsyncCommands, RedisError};
use serde::Serialize;

/// The name of the Redis set that contains the allowlist.
const SET_NAME: &str = "allowlist";

/// A tuple containing a status code and a JSON-serialized request summary.
type CodedSummary = (StatusCode, Json<RequestSummary>);

/// The result of a request, which is either a successful response or an error response.
type RequestResult = Result<CodedSummary, CodedSummary>;

/// Connection to the Redis database with a default request summary and parsed address.
struct PreparedConnection(
    PooledConnection<'static, RedisConnectionManager>,
    RequestSummary,
    String,
);

/// The connection pool for the Redis database.
type ConnectionPool = Pool<RedisConnectionManager>;

#[derive(Clone, Serialize)]
struct RequestSummary {
    request_address: String,
    parsed_address: Option<String>,
    is_allowed: Option<bool>,
    message: String,
}

#[derive(strum_macros::Display)]
enum SummaryMessage {
    #[strum(to_string = "Added to allowlist")]
    AddedToAllowlist,
    #[strum(to_string = "Already allowed")]
    AlreadyAllowed,
    #[strum(to_string = "Found in allowlist")]
    FoundInAllowlist,
    #[strum(to_string = "Not found in allowlist")]
    NotFoundInAllowlist,
}

/// Result of a Redis set operation.
enum SetOperationResult {
    AddedToSet,
    IsMember,
}

#[derive(thiserror::Error, Debug)]
enum RequestError {
    #[error("Add member error: {0}")]
    AddMember(RedisError),
    #[error("Could not parse address: {0}")]
    CouldNotParseAddress(AccountAddressParseError),
    #[error("Could not parse address: {0}")]
    CouldNotParseRequestPath(PathRejection),
    #[error("Is member lookup error: {0}")]
    IsMemberLookup(RedisError),
    #[error("Redis connection error: {0}")]
    RedisConnection(RunError<RedisError>),
}

enum CodedRequestSummary {
    BadRequest { request_summary: RequestSummary },
    InternalError { request_summary: RequestSummary },
    SuccessfulRequest { request_summary: RequestSummary },
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
    PreparedConnection(mut connection, mut request_summary, parsed_address): PreparedConnection,
) -> RequestResult {
    if connection
        .sismember::<&str, &str, i32>(SET_NAME, &parsed_address)
        .await
        .map_err(|error| {
            CodedSummary::from(CodedRequestSummary::InternalError {
                request_summary: RequestSummary {
                    message: RequestError::IsMemberLookup(error).to_string(),
                    ..request_summary.clone()
                },
            })
        })?
        != i32::from(SetOperationResult::IsMember)
    {
        request_summary.is_allowed = Some(false);
        request_summary.message = SummaryMessage::NotFoundInAllowlist.to_string();
    };
    CodedRequestSummary::SuccessfulRequest { request_summary }.into()
}

async fn add_to_allowlist(
    PreparedConnection(mut connection, mut request_summary, parsed_address): PreparedConnection,
) -> RequestResult {
    if connection
        .sadd::<&str, &str, i32>(SET_NAME, &parsed_address)
        .await
        .map_err(|error| {
            CodedSummary::from(CodedRequestSummary::InternalError {
                request_summary: RequestSummary {
                    message: RequestError::AddMember(error).to_string(),
                    ..request_summary.clone()
                },
            })
        })?
        == i32::from(SetOperationResult::AddedToSet)
    {
        request_summary.message = SummaryMessage::AddedToAllowlist.to_string();
    } else {
        request_summary.message = SummaryMessage::AlreadyAllowed.to_string();
    };
    CodedRequestSummary::SuccessfulRequest { request_summary }.into()
}

#[async_trait]
impl<S> FromRequestParts<S> for PreparedConnection
where
    ConnectionPool: FromRef<S>,
    S: Send + Sync,
{
    type Rejection = CodedSummary;

    async fn from_request_parts(parts: &mut Parts, state: &S) -> Result<Self, Self::Rejection> {
        // Try to extract the request address from the path.
        let mut request_summary = RequestSummary {
            request_address: "".to_string(),
            parsed_address: None,
            is_allowed: None,
            message: "".to_string(),
        };
        let Path(request_address): Path<String> = Path::from_request_parts(parts, state)
            .await
            .map_err(|error| {
                CodedSummary::from(CodedRequestSummary::BadRequest {
                    request_summary: RequestSummary {
                        message: RequestError::CouldNotParseRequestPath(error).to_string(),
                        ..request_summary.clone()
                    },
                })
            })?;
        request_summary.request_address.clone_from(&request_address);

        // Try parsing address.
        let account_address =
            AccountAddress::try_from(request_address.clone()).map_err(|error| {
                CodedSummary::from(CodedRequestSummary::BadRequest {
                    request_summary: RequestSummary {
                        message: RequestError::CouldNotParseAddress(error).to_string(),
                        ..request_summary.clone()
                    },
                })
            })?;
        let parsed_address = account_address.to_hex_literal();
        request_summary.parsed_address = Some(parsed_address.clone());

        // Get a connection to the Redis database.
        let pool = ConnectionPool::from_ref(state);
        let connection = pool.get_owned().await.map_err(|error| {
            CodedSummary::from(CodedRequestSummary::InternalError {
                request_summary: RequestSummary {
                    message: RequestError::RedisConnection(error).to_string(),
                    ..request_summary.clone()
                },
            })
        })?;

        // Assume the address is allowed by default.
        request_summary.is_allowed = Some(true);
        request_summary.message = SummaryMessage::FoundInAllowlist.to_string();
        Ok(Self(connection, request_summary, parsed_address))
    }
}

/// Integer representation of a Redis set operation result.
impl From<SetOperationResult> for i32 {
    fn from(result: SetOperationResult) -> Self {
        match result {
            SetOperationResult::AddedToSet => 1,
            SetOperationResult::IsMember => 1,
        }
    }
}

impl From<CodedRequestSummary> for RequestResult {
    fn from(result: CodedRequestSummary) -> Self {
        match result {
            CodedRequestSummary::BadRequest { .. } => Err(CodedSummary::from(result)),
            CodedRequestSummary::InternalError { .. } => Err(CodedSummary::from(result)),
            CodedRequestSummary::SuccessfulRequest { .. } => Ok(CodedSummary::from(result)),
        }
    }
}

impl From<CodedRequestSummary> for CodedSummary {
    fn from(result: CodedRequestSummary) -> Self {
        match result {
            CodedRequestSummary::BadRequest { request_summary } => {
                (StatusCode::BAD_REQUEST, Json(request_summary))
            }
            CodedRequestSummary::InternalError { request_summary } => {
                (StatusCode::INTERNAL_SERVER_ERROR, Json(request_summary))
            }
            CodedRequestSummary::SuccessfulRequest { request_summary } => {
                (StatusCode::OK, Json(request_summary))
            }
        }
    }
}
