# carv-contracts - protocol contract

## CarvProtocolService.sol
### Deleted Content
- remove some get func
- update erc20 token transfer logic

### Added Content
- verify_attestation 
> Earnings are obtained from the vault contract

- verify_attestation_batch
> Earnings are obtained from the vault contract

### Modified Content
- pay_profit is changed to pay_platform to obtain earnings from CarvVault

## Add CarvVault contract
> Responsible for distributing CARV rewards to verifiers
- set service profit 
- deposit service reward