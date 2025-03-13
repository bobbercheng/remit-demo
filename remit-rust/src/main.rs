use actix_cors::Cors;
use actix_web::{middleware, App, HttpServer};
use aws_config::meta::region::RegionProviderChain;
use aws_sdk_dynamodb::Client as DynamoDbClient;
use paperclip::actix::{
    web::scope,
    OpenApiExt,
};
use std::sync::Arc;
use tracing_actix_web::TracingLogger;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

mod api;
mod config;
mod errors;
mod integrations;
mod models;
mod repositories;
mod services;

use config::get_config;
use repositories::{TransactionRepository, ExchangeRateRepository};
use services::RemittanceService;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Initialize tracing
    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::new(
            std::env::var("RUST_LOG").unwrap_or_else(|_| {
                let config = get_config();
                format!("remit_rust={},actix_web=info", config.server.log_level)
            }),
        ))
        .with(tracing_subscriber::fmt::layer())
        .init();
    
    // Load configuration
    let config = get_config();
    
    // Configure AWS SDK
    let region_provider = RegionProviderChain::first_try(config.database.region.clone())
        .or_default_provider();
    
    let aws_config = aws_config::from_env()
        .region(region_provider)
        .endpoint_url(&config.database.dynamodb_endpoint)
        .credentials_provider(aws_config::Credentials::new(
            &config.database.access_key_id,
            &config.database.secret_access_key,
            None,
            None,
            "remit-rust",
        ))
        .load()
        .await;
    
    // Create DynamoDB client
    let dynamodb_client = DynamoDbClient::new(&aws_config);
    
    // Create repositories
    let transaction_repo = TransactionRepository::new(dynamodb_client.clone());
    let exchange_rate_repo = ExchangeRateRepository::new(dynamodb_client);
    
    // Create services
    let remittance_service = RemittanceService::new(transaction_repo.clone(), exchange_rate_repo);
    
    // Start HTTP server
    let server_host = config.server.host.clone();
    let server_port = config.server.port;
    let workers = config.server.workers;
    
    tracing::info!("Starting server at http://{}:{}", server_host, server_port);
    
    HttpServer::new(move || {
        // CORS configuration
        let cors = Cors::default()
            .allow_any_origin()
            .allow_any_method()
            .allow_any_header()
            .max_age(3600);
        
        App::new()
            // Middleware
            .wrap(TracingLogger::default())
            .wrap(middleware::Compress::default())
            .wrap(middleware::NormalizePath::trim())
            .wrap(cors)
            
            // OpenAPI documentation
            .wrap_api()
            .with_json_spec_at("/api/spec")
            .with_swagger_ui_at("/api/docs")
            
            // Services
            .service(
                scope("/api/v1")
                    .app_data(actix_web::web::Data::new(remittance_service.clone()))
                    .app_data(actix_web::web::Data::new(transaction_repo.clone()))
                    .configure(api::configure)
            )
            
            // Build the app
            .build()
    })
    .workers(workers)
    .bind(format!("{}:{}", server_host, server_port))?
    .run()
    .await
} 