use axum::{
    routing::{get, post},
    Router,
};
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

async fn add_to_allowlist() -> &'static str {
    "Added to allowlist"
}