use axum::{
    http::StatusCode,
    routing::{get, post},
    Json, Router,
};
use move_core_types::account_address::AccountAddress;
use serde::{Deserialize, Serialize};
use tokio;

#[tokio::main]
async fn main() {
    let app = Router::new()
        .route("/", get(is_allowed))
        .route("/", post(add_to_allowlist));

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn is_allowed() -> &'static str {
    "You are allowed"
}

async fn add_to_allowlist(
    Json(payload): Json<AddAddressRequest>,
) -> (StatusCode, Json<AddAddressResult>) {
    if let Ok(account_address) = AccountAddress::try_from(payload.address.clone()) {
        let result = AddAddressResult {
            requested_address: payload.address,
            parsed_address: Some(account_address.to_hex_literal()),
            result: "Added".to_string(),
        };
        (StatusCode::CREATED, Json(result))
    } else {
        (
            StatusCode::BAD_REQUEST,
            Json(AddAddressResult {
                requested_address: payload.address,
                parsed_address: None,
                result: "Could not parse address".to_string(),
            }),
        )
    }
}

#[derive(Deserialize)]
struct AddAddressRequest {
    address: String,
}

#[derive(Serialize)]
struct AddAddressResult {
    requested_address: String,
    parsed_address: Option<String>,
    result: String,
}
