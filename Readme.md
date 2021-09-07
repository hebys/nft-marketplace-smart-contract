## Hebys Smart Contracts

![HebysV2ContractDesign](https://user-images.githubusercontent.com/16240508/132330253-bc9da3a9-42dd-49d7-90c1-2e43f691b669.png)

The structure adopted in Hebys Contracts V2 version was created as stated above. Each Contract interacts with the contract with which it communicates in accordance with the Interface.
Communication states are separated for Read/Write roles according to the contract's property and the information it contains.
The arrow signs above show the communication status of the contracts with each other.

### Storage
Storage Contracts in Hebys Contracts were created by adopting the eternal storage structure.
Due to their nature, Smart Contracts cannot be updated and are redeployed, so keeping the data on ProxyContract means that the data will be lost in an unusual scenario.
In this created structure, in any unusual situation that may occur on ProxyContract, ProxyContract, which does not keep any information on it, is redeployed and allows the same data to be processed again.

#### Sell Storage
Sell Storage Contract contains the sell data. It is available only to the Read/Write authorization of the SellProxy contract.
#### Fee Storage
Fee Storage Contract contains the fee data. It is available only to the Read authorization of the SellProxy contract.

### Proxy
Sell Proxy undertakes the task of interpreting the data and methods in other related Contracts that do not contain any data on the Contract.
While other contracts do not specify a business logic in themselves, Proxy Contract undertakes this main business task. Various requests are made special to Proxy Contract only with Read/Write authorization.
After the Proxy Contract makes the necessary validations, the incoming data or request makes a request to the contract that it will interact with in accordance with the Interface.

### Hebys ERC1155
Hebys ERC1155 Contract essentially complies with the ERC1155 Standard it has adopted. Keeping the royalty management on the Hebys ERC1155 Contract in V2 version provides a trust mechanism for the Creator, because the royalty he will receive is directly stated on the NFT that he mints. 


>This structure is open to be updated in different versions with necessary arrangements as a result of different approaches in necessary situations and scenarios.
