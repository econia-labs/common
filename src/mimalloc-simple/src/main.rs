use mimalloc::MiMalloc;
use tokio;

#[global_allocator]
static GLOBAL: MiMalloc = MiMalloc;

#[tokio::main]
async fn main() -> Result<(), ()> {
    println!("Hello, world!");
    Ok(())
}
