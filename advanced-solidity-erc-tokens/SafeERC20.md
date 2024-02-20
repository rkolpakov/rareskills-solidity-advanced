### Why does the SafeERC20 program exist and when should it be used?

There are several problems with regular `ERC20` tokens:
- iconsistent return values: `transfer` and `approve`, are expected to return boolean values indicating success or failure. However, some implementations do not return any value;
- lack of revert on failure: `ERC20` functions should revert in case of a failure. Some implementations, might not revert on failure;
- gas limitations: direct `ERC20` token interactions can sometimes run into gas-related issues, especially if the token contract does not implement the standard properly.

`SafeERC20` introduces wrapper functions that standardize interactions with ERC20 tokens, handling these problems of different token implementations.