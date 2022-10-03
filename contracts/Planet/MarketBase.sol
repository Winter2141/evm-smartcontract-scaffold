// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.4 <0.9.0;

interface IMarketBase {
    // ----- Data and Events for Market ----- //

    /**
     * @dev Token info data structure
     * @param collection  The ERC721/ERC1155 collection address
     * @param tokenId  The token ID placed in the collection
     * @param quantity  The quantity of tokens (only meaningful for ERC1155 token)
     */
    struct TokenInfo {
        address collection;
        uint256 tokenId;
        uint256 quantity;
    }

    /**
     * @dev Payment info data structure
     * @param paymentToken  The address of the token accepted as payment for the order
     * @param price  The amount of payment token(considering decimals)
     */
    struct PaymentInfo {
        address paymentToken;
        uint256 price;
    }

    /**
     * @dev Order info data structure
     * @param orderId  The identifier of the order, incrementing uint256 starting from 0
     * @param orderType  The type of the order, 1 is sale order, 2 is auction order
     * @param orderState  The state of the order, 1 is open, 2 is filled, 3 is cancelled, 4 is taken down by manager
     * @param token  The token info placed in the order
     * @param payment  The payment info accepted as payment for the order
     * @param endTime  The end time of the auction (only meaningful for auction order)
     * @param seller  The address of the seller that created the order
     * @param buyer  The address of the buyer of the order
     * @param bids  The number of bids placed on the order (only meaningful for auction orders)
     * @param lastBidder  The address of the last bidder that bids on the order (only meaningful for auction orders)
     * @param lastBid  The last bid price on the order (only meaningful for auction orders)
     * @param createTime  The timestamp of the order creation
     * @param updateTime  The timestamp of last order info update
     */
    struct OrderInfo {
        uint256 orderId;
        uint256 orderType;
        uint256 orderState;
        TokenInfo token;
        PaymentInfo payment;
        uint256 endTime;
        address seller;
        address buyer;
        uint256 bids;
        address lastBidder;
        uint256 lastBid;
        uint256 createTime;
        uint256 updateTime;
    }

    /**
     * @dev Offer info data structure
     * @param offerId  The identifier of the offer, incrementing uint256 starting from 0
     * @param offerState  The state of the offer, 1 is open, 2 is accepted, 3 is cancelled
     * @param token  The token info placed in the offer
     * @param payment  The payment info accepted as payment for the offer
     * @param offerer  The address of the offerer that created the offer
     * @param acceptor  The address of the acceptor that accepted the offer
     * @param createTime  The timestamp of the offer creation
     * @param updateTime  The timestamp of last offer info update
     */
    struct OfferInfo {
        uint256 offerId;
        uint256 offerState;
        TokenInfo token;
        PaymentInfo payment;
        address offerer;
        address acceptor;
        uint256 createTime;
        uint256 updateTime;
    }

    /**
     * @dev MUST emit when a new sale order is created in Market.
     * The `seller` argument MUST be the address of the seller who created the order.
     * The `orderId` argument MUST be the id of the order created.
     * The `collection` argument MUST be the address of the collection.
     * The `tokenId` argument MUST be the token type placed on sale.
     * The `quantity` argument MUST be the quantity of tokens placed on sale.
     * The `paymentToken` argument MUST be the address of the token accepted as payment for the order.
     * The `price` argument MUST be the fixed price asked for the sale order.
     */
    event OrderForSale(address seller, uint256 indexed orderId, address indexed collection, uint256 indexed tokenId, uint256 quantity, address paymentToken, uint256 price);

    /**
     * @dev MUST emit when a new auction order is created in Market.
     * The `seller` argument MUST be the address of the seller who created the order.
     * The `orderId` argument MUST be the id of the order created.
     * The `collection` argument MUST be the address of the collection.
     * The `tokenId` argument MUST be the token type placed on auction.
     * The `quantity` argument MUST be the quantity of tokens placed on auction.
     * The `paymentToken` argument MUST be the address of the token accepted as payment for the auction.
     * The `minPrice` argument MUST be the minimum starting price for the auction bids.
     * The `endTime` argument MUST be the time for ending the auction.
     */
    event OrderForAuction(address seller, uint256 indexed orderId, address indexed collection, uint256 indexed tokenId, uint256 quantity, address paymentToken, uint256 minPrice, uint256 endTime);

    /**
     * @dev MUST emit when a bid is placed on an auction order.
     * The `orderId` argument MUST be the id of the order been bid on.
     * The `bidder` argument MUST be the address of the bidder who made the bid.
     * The `price` argument MUST be the price of the bid.
     */
    event OrderBid(uint256 indexed orderId, address indexed bidder, uint256 price);

    /**
     * @dev MUST emit when an order is filled.
     * The `seller` argument MUST be the address of the seller who created the order.
     * The `buyer` argument MUST be the address of the buyer in the fulfilled order.
     * The `orderId` argument MUST be the id of the order fulfilled.
     * The `paymentToken` argument MUST be the address of the token used as payment for the fulfilled order.
     * The `price` argument MUST be the price of the fulfilled order.
     */
    event OrderFilled(address seller, address indexed buyer, uint256 indexed orderId, address indexed paymentToken, uint256 price);

    /**
     * @dev MUST emit when an order is canceled.
     * @dev Only an open sale order or an auction order with no bid yet can be canceled
     * The `orderId` argument MUST be the id of the order canceled.
     */
    event OrderCanceled(uint256 indexed orderId);

    /**
     * @dev MUST emit when an order is taken down by manager due to inappropriate content.
     * @dev Only an open order can be taken down.
     * The `orderId` argument MUST be the id of the order taken down.
     * The `manager` argument MUST be the address of the manager who took down the order.
     */
    event OrderTakenDown(uint256 indexed orderId, address indexed manager);

    /**
     * @dev MUST emit when an order has its price changed.
     * @dev Only an open sale order or an auction order with no bid yet can have its price changed.
     * @dev For sale orders, the fixed price asked for the order is changed.
     * @dev for auction orders, the minimum starting price for the bids is changed.
     * The `seller` argument MUST be the address of the seller who created the order.
     * The `orderId` argument MUST be the id of the order with the price change.
     * The `oldPrice` argument MUST be the original price of the order before the price change.
     * The `newPrice` argument MUST be the new price of the order after the price change.
     */
    event OrderPriceChanged(address indexed seller, uint256 indexed orderId, uint256 oldPrice, uint256 newPrice);

    /**
     * @dev MUST emit when a new offer is created in Market.
     * The `offerer` argument MUST be the address of the offerer who created the offer.
     * The `offerId` argument MUST be the id of the offer created.
     * The `collection` argument MUST be the address of the collection.
     * The `tokenId` argument MUST be the token type placed on offer.
     * The `quantity` argument MUST be the quantity of tokens placed on offer.
     * The `paymentToken` argument MUST be the address of the token accepted as payment for the offer.
     * The `price` argument MUST be the fixed price asked for the offer.
     */
    event OfferCreated(address indexed offerer, uint256 indexed offerId, address collection, uint256 tokenId, uint256 quantity, address paymentToken, uint256 price);

    /**
     * @dev MUST emit when the offer is accepted in Market.
     * The `offerId` argument MUST be the id of the offer accepted.
     * The `acceptor` argument MUST be the address of the acceptor who accepted the offer.
     */
    event OfferAccepted(uint256 indexed offerId, address indexed acceptor);

    /**
     * @dev MUST emit when the offer is canceled in Market.
     * The `offerId` argument MUST be the id of the offer canceled.
     */
    event OfferCanceled(uint256 indexed offerId);


    // ----- Trading orders in Market ----- //

    /**
     * @notice Create a new order for sale at a fixed price.
     * @param collection The contract address of collection.
     * @param tokenId The token placed on sale.
     * @param quantity The quantity of tokens placed on sale.
     * @param paymentToken The address of the token accepted as payment for the order.
     * @param price The fixed price asked for the sale order.
     */
    function createOrderForSale(address collection, uint256 tokenId, uint256 quantity, address paymentToken, uint256 price) external;

    /**
     * @notice Create a new order for auction.
     * @param collection The contract address of collection.
     * @param tokenId The token placed on auction.
     * @param quantity The quantity of tokens placed on auction.
     * @param paymentToken The address of the token accepted as payment for the auction.
     * @param minPrice The minimum starting price for bidding on the auction.
     * @param endTime The time for ending the auction.
     */
    function createOrderForAuction(address collection, uint256 tokenId, uint256 quantity, address paymentToken, uint256 minPrice, uint256 endTime) external;

    /**
     * @notice Buy a sale order with fixed price.
     * @dev The value of the transaction must equal to the fixed price asked for the order.
     * @param orderId The id of the fixed price sale order.
     */
    function buyForOrder(uint256 orderId) external payable;

    /**
     * @notice Bid on an auction order.
     * @dev The value of the transaction must be greater than or equal to the minimum starting price of the order.
     * @dev If the order has past bid(s), the value of the transaction must be greater than the last bid.
     * @param orderId The id of the auction order.
     * @param value The price value of the bid.
     */
    function bidForOrder(uint256 orderId, uint256 value) external payable;

    /**
     * @notice Cancel an order.
     * @dev Only an open sale order or an auction order with no bid yet can be canceled.
     * @dev Only an order's seller can cancel the order.
     * @param orderId The id of the order to be canceled.
     */
    function cancelOrder(uint256 orderId) external;

    /**
     * @notice Take down an order due to inappropriate content.
     * @dev Only an open order can be taken down.
     * @dev Only a contract manager can take down orders.
     * @param orderId The id of the order to be taken down.
     */
    function takeDownOrder(uint256 orderId) external;

    /**
     * @notice Settle an auction.
     * @dev Only an auction order past its end time can be settled.
     * @dev Anyone can settle an auction.
     * @param orderId The id of the order to be settled.
     */
    function settleOrderForAuction(uint256 orderId) external;

    /**
     * @notice Change the price of an order.
     * @dev Only an open sale order or an auction order with no bid yet can have its price changed.
     * @dev For sale orders, the fixed price asked for the order is changed.
     * @dev for auction orders, the minimum starting price for the bids is changed.
     * @dev Only an order's seller can change its price.
     * @param orderId The id of the order with its price to be changed.
     * @param price The new price of the order.
     */
    function changeOrderPrice(uint256 orderId, uint256 price) external;

    /**
     * @notice Create a new offer.
     * @param collection The address of the collection.
     * @param tokenId The token placed on offer.
     * @param quantity The quantity of tokens placed on offer.
     * @param paymentToken The address of the token accepted as payment for the offer.
     * @param price The fixed price asked for the offer.
     */
    function makeOffer(address collection, uint256 tokenId, uint256 quantity, address paymentToken, uint256 price) external payable;

    /**
     * @notice Accept an offer.
     * @param offerId The id of the offer.
     */
    function acceptOffer(uint256 offerId) external;

    /**
     * @notice Cancel an offer.
     * @param offerId The id of the offer.
     */
    function cancelOffer(uint256 offerId) external;
}
