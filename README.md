# Shoppy
A simple wrapper for the Shopify mobile buy sdk to simplify interactions with Shopify.

## Features

- **Collection Management**: Efficiently manage product collections with functionalities like:
  - `ShopDataManager.resetSharedCollectionDataStore()`: Resets the shared collection data store.
  - `ShopDataManager.shared.fetchCollections { [weak self] collections in ... }`: Fetches collections and handles them in the provided closure.
  - `ShopDataManager.shared.collectionAtIndex(index: i)`: Retrieves a collection at a specified index.
  - `ShopDataManager.shared.numberOfCollectionsLoaded()`: Returns the number of collections currently loaded.
  - `ShopDataManager.shared.hasReachedEndOfCollections()`: Checks if the end of the collection list has been reached.

- **Cart Management**: Offers robust cart validation and management features:
  - `CartController.shared.validateCart { isValid cart in ... }`: Validates the current state of the cart.

- **Account Management**: Ensures secure login and account handling:
  - `AccountManager.shared.validateLogin { [weak self] isLoggedIn in ... }`: Validates the login status of the current user.
