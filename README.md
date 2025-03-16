# remit-demo

## Java version
### Cursor model
Claude-3.7-sonnet-thinking
### prompt
```
Build a near real-time cross-border remittance service between India and Canada.  Here is rough requirements:
- User Registration & KYC: out of scope. Assume there is user service that provide all use information
- Fund Collection in India: collecting funds via UPI. Payment aggregator or partner bank places user funds into a secure account until transfer is executed.
- Currency Conversion & Outward Remittance: Partnership with an AD Bank via API
- Transmission to Canada: FinTech Partner – Use a cross-border aggregator(Wise) that can deposit funds into Canadian bank accounts in near real time.

Use sequential-thinking, create a remittance service with java and springboot. Explain sequence workflow and high level design before writing code. Define remittance API with openapi JSON swagger firstly. Follow best practices to have well documented code to reflect workflow and design.  Put all changing variants into config files with explaination. Use reactive programming. Define db schema. Persist necesary data with flyway into dynamodb that runs with docker. Ignore small errors in the begin and fix them all in the end. Have test code to cover critical happy path and common failures. 
```
### sequential-thing
8 steps
### addtinal follow up
```JSON swagger of remittance API spec is missed, create it```


## Typescript version
### Cursor model
Claude-3.7-sonnet-thinking
### prompt

```
Build a near real-time cross-border remittance service between India and Canada.  Here is rough requirements:
- User Registration & KYC: out of scope. Assume there is user service that provide all use information
- Fund Collection in India: collecting funds via UPI. Payment aggregator or partner bank places user funds into a secure account until transfer is executed.
- Currency Conversion & Outward Remittance: Partnership with an AD Bank via API
- Transmission to Canada: FinTech Partner – Use a cross-border aggregator(Wise) that can deposit funds into Canadian bank accounts in near real time.

Use sequential-thinking, create a remittance backend service with typescript and nextjs. Explain sequence workflow and high level design before writing code. Define remittance API with openapi JSON swagger. Follow best practices to have well documented code to reflect workflow and design.  Put all changing variants into config files with explaination. Use functional programming. Define db schema. Persist necesary data into dynamodb that runs with docker. Have test code to cover critical happy path and common failures.
```
### sequential-thing
8 steps

## Elixir version
### Cursor model
Claude-3.7-sonnet-thinking
### prompt

```
Build a near real-time cross-border remittance service between India and Canada.  Here is rough requirements:
- User Registration & KYC: out of scope. Assume there is user service that provide all use information
- Fund Collection in India: collecting funds via UPI. Payment aggregator or partner bank places user funds into a secure account until transfer is executed.
- Currency Conversion & Outward Remittance: Partnership with an AD Bank via API
- Transmission to Canada: FinTech Partner – Use a cross-border aggregator(Wise) that can deposit funds into Canadian bank accounts in near real time.

Use sequential-thinking, create a remittance backend service with elixir and phoenix. Explain sequence workflow and high level design before writing code. Define remittance API with openapi JSON swagger. Follow best practices to have well documented code to reflect workflow and design.  Put all changing variants into config files with explaination. Use functional programming. Define db schema. Persist necesary data into dynamodb that runs with docker. Have test code to cover critical happy path and common failures.
```
### sequential-thing
8 steps

## Python version
### Cursor model
Claude-3.7-sonnet-thinking
### prompt

```
Build a near real-time cross-border remittance service between India and Canada.  Here is rough requirements:
- User Registration & KYC: out of scope. Assume there is user service that provide all use information
- Fund Collection in India: collecting funds via UPI. Payment aggregator or partner bank places user funds into a secure account until transfer is executed.
- Currency Conversion & Outward Remittance: Partnership with an AD Bank via API
- Transmission to Canada: FinTech Partner – Use a cross-border aggregator(Wise) that can deposit funds into Canadian bank accounts in near real time.

Use sequential-thinking, create a remittance backend service with python and fastapi. Explain sequence workflow and high level design before writing code. Define remittance API with openapi JSON swagger. Follow best practices to have well documented code to reflect workflow and design.  Put all changing variants into config files with explaination. Use functional programming and strong types. Define db schema. Persist necesary data into dynamodb that runs with docker. Have test code to cover critical happy path and common failures.
```
### sequential-thing
8 steps

## Rust version
### Cursor model
Claude-3.7-sonnet-thinking
### prompt

```
Build a near real-time cross-border remittance service between India and Canada.  Here is rough requirements:
- User Registration & KYC: out of scope. Assume there is user service that provide all use information
- Fund Collection in India: collecting funds via UPI. Payment aggregator or partner bank places user funds into a secure account until transfer is executed.
- Currency Conversion & Outward Remittance: Partnership with an AD Bank via API
- Transmission to Canada: FinTech Partner – Use a cross-border aggregator(Wise) that can deposit funds into Canadian bank accounts in near real time.

Use sequential-thinking, create a remittance backend service with Rust and Actix. Explain sequence workflow and high level design before writing code. Define remittance API with openapi JSON swagger. Follow best practices to have well documented code to reflect workflow and design.  Put all changing variants into config files with explaination. Use functional programming. Define db schema. Persist necesary data into dynamodb that runs with docker. Have test code to cover critical happy path and common failures.
```
### sequential-thing
10 steps

## Go version
### Cursor model
Claude-3.7-sonnet-thinking
### prompt

```
Build a near real-time cross-border remittance service between India and Canada.  Here is rough requirements:
- User Registration & KYC: out of scope. Assume there is user service that provide all use information
- Fund Collection in India: collecting funds via UPI. Payment aggregator or partner bank places user funds into a secure account until transfer is executed.
- Currency Conversion & Outward Remittance: Partnership with an AD Bank via API
- Transmission to Canada: FinTech Partner – Use a cross-border aggregator(Wise) that can deposit funds into Canadian bank accounts in near real time.

Use sequential-thinking, create a remittance backend service with Golang and Gin. Explain sequence workflow and high level design before writing code. Define remittance API with openapi JSON swagger. Follow best practices to have well documented code to reflect workflow and design.  Put all changing variants into config files with explaination. Use functional programming. Define db schema. Persist necesary data into dynamodb that runs with docker. Have test code to cover critical happy path and common failures.
```
### sequential-thing
6 steps
