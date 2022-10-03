// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "hardhat/console.sol";

// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // //
//  ██████╗  ██████╗  ██████╗ ██████╗     ██╗  ██╗ █████╗ ██████╗ ███╗   ███╗ █████╗     ████████╗ ██████╗ ██╗  ██╗███████╗███╗   ██╗  //
// ██╔════╝ ██╔═══██╗██╔═══██╗██╔══██╗    ██║ ██╔╝██╔══██╗██╔══██╗████╗ ████║██╔══██╗    ╚══██╔══╝██╔═══██╗██║ ██╔╝██╔════╝████╗  ██║  //
// ██║  ███╗██║   ██║██║   ██║██║  ██║    █████╔╝ ███████║██████╔╝██╔████╔██║███████║       ██║   ██║   ██║█████╔╝ █████╗  ██╔██╗ ██║  //
// ██║   ██║██║   ██║██║   ██║██║  ██║    ██╔═██╗ ██╔══██║██╔══██╗██║╚██╔╝██║██╔══██║       ██║   ██║   ██║██╔═██╗ ██╔══╝  ██║╚██╗██║  //
// ╚██████╔╝╚██████╔╝╚██████╔╝██████╔╝    ██║  ██╗██║  ██║██║  ██║██║ ╚═╝ ██║██║  ██║       ██║   ╚██████╔╝██║  ██╗███████╗██║ ╚████║  //
//  ╚═════╝  ╚═════╝  ╚═════╝ ╚═════╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝       ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝  //
// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // //

library LibRoyaltiesV2 {
	/*
	 *   bytes4(keccak256('getRaribleV2Royalties(uint256)')) == 0xcad96cca
	 */
	bytes4 constant _INTERFACE_ID_ROYALTIES = 0xcad96cca;
}

abstract contract AbstractRoyalties {
	mapping(uint256 => LibPart.Part[]) internal royalties;

	function _saveRoyalties(uint256 id, LibPart.Part[] memory _royalties) internal {
		uint256 totalValue;
		for (uint256 i = 0; i < _royalties.length; i++) {
			require(_royalties[i].account != address(0x0), "Recipient should be present");
			require(_royalties[i].value != 0, "Royalty value should be positive");
			totalValue += _royalties[i].value;
			royalties[id].push(_royalties[i]);
		}
		require(totalValue < 10000, "Royalty total value should be < 10000");
		_onRoyaltiesSet(id, _royalties);
	}

	function _updateAccount(
		uint256 _id,
		address _from,
		address _to
	) internal {
		uint256 length = royalties[_id].length;
		for (uint256 i = 0; i < length; i++) {
			if (royalties[_id][i].account == _from) {
				royalties[_id][i].account = payable(address(uint160(_to)));
			}
		}
	}

	function _onRoyaltiesSet(uint256 id, LibPart.Part[] memory _royalties) internal virtual;
}

interface RoyaltiesV2 {
	event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);

	function getRaribleV2Royalties(uint256 id) external view returns (LibPart.Part[] memory);
}

///
/// @dev Interface for the NFT Royalty Standard
///
//interface IERC2981 is IERC165 {
interface IERC2981 {
	/// ERC165 bytes to add to interface array - set in parent contract
	/// implementing this standard
	///
	/// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
	/// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
	/// _registerInterface(_INTERFACE_ID_ERC2981);

	/// @notice Called with the sale price to determine how much royalty
	//          is owed and to whom.
	/// @param _tokenId - the NFT asset queried for royalty information
	/// @param _salePrice - the sale price of the NFT asset specified by _tokenId
	/// @return receiver - address of who should be sent the royalty payment
	/// @return royaltyAmount - the royalty payment amount for _salePrice
	function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount);
}

library LibRoyalties2981 {
	/*
	 * https://eips.ethereum.org/EIPS/eip-2981: bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
	 */
	bytes4 constant _INTERFACE_ID_ROYALTIES = 0x2a55205a;
	uint96 constant _WEIGHT_VALUE = 1000000;

	/*Method for converting amount to percent and forming LibPart*/
	function calculateRoyalties(address to, uint256 amount) internal view returns (LibPart.Part[] memory) {
		LibPart.Part[] memory result;
		if (amount == 0) {
			return result;
		}
		uint256 percent = ((amount * 100) / _WEIGHT_VALUE) * 100;
		require(percent < 10000, "Royalties 2981, than 100%");
		result = new LibPart.Part[](1);
		result[0].account = payable(to);
		result[0].value = uint96(percent);
		return result;
	}
}

contract RoyaltiesV2Impl is AbstractRoyalties, RoyaltiesV2, IERC2981 {
	function getRaribleV2Royalties(uint256 id) external view override returns (LibPart.Part[] memory) {
		return royalties[id];
	}

	function _onRoyaltiesSet(uint256 id, LibPart.Part[] memory _royalties) internal override {
		emit RoyaltiesSet(id, _royalties);
	}

	/*
	 *Token (ERC721, ERC721Minimal, ERC721MinimalMeta, ERC1155 ) can have a number of different royalties beneficiaries
	 *calculate sum all royalties, but royalties beneficiary will be only one royalties[0].account, according to rules of IERC2981
	 */
	function royaltyInfo(uint256 id, uint256 _salePrice) public view virtual override returns (address receiver, uint256 royaltyAmount) {
		if (royalties[id].length == 0) {
			receiver = address(0);
			royaltyAmount = 0;
			return (receiver, royaltyAmount);
		}
		LibPart.Part[] memory _royalties = royalties[id];
		receiver = _royalties[0].account;
		uint256 percent;
		for (uint256 i = 0; i < _royalties.length; i++) {
			percent += _royalties[i].value;
		}
		//don`t need require(percent < 10000, "Token royalty > 100%"); here, because check later in calculateRoyalties
		royaltyAmount = (percent * _salePrice) / 10000;
	}
}

library LibPart {
	bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");

	struct Part {
		address payable account;
		uint96 value;
	}

	function hash(Part memory part) internal pure returns (bytes32) {
		return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
	}
}

contract GoodKarmaToken is ERC1155, RoyaltiesV2Impl, Ownable, ReentrancyGuard {
	using Strings for uint256;
	using Address for address;
	uint8 public constant GoodKarmaTokenID = 0; // default is zero
	uint96 public constant royaltyBasisPoints = 9900;
	bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
	uint256 public MAX_SUPPLY = 2347;
	string public tokenUri = "ipfs://QmZhUoNHxkaJNaUtiMNtSSxxEG9Sj2vEXAFJ6mRso6h58D";
	string public name = "Good Karma Token";
	address private VandalzContract;

	constructor() ERC1155(tokenUri) {
		_mint(msg.sender, GoodKarmaTokenID, MAX_SUPPLY, "");
		_setRoyalties(payable(msg.sender));
	}

	function uri(uint256) public view override returns (string memory) {
		return tokenUri;
	}

	function setTokenUri(string memory _newUri) external onlyOwner {
		tokenUri = _newUri;
	}

	function mintEmergencySupply(uint256 _numNewTokens) external onlyOwner {
		MAX_SUPPLY += _numNewTokens;
		_mint(msg.sender, GoodKarmaTokenID, _numNewTokens, "");
	}

	function withdraw() external onlyOwner {
		uint256 _balance = address(this).balance;
		require(_balance > 0, "No amount to withdraw");
		Address.sendValue(payable(owner()),_balance);
	}

	function setVandalzContract(address _vandalzAddress) external onlyOwner {
		require(address(_vandalzAddress) != address(0) && _vandalzAddress.isContract(), "Invalid Address");
		VandalzContract = _vandalzAddress;
	}

	function burnTokenForVandal(address holderAddress) external {
		require(msg.sender == VandalzContract, "Invalid Burn Caller");
		_burn(holderAddress, GoodKarmaTokenID, 1);
	}

	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
		if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
			return true;
		}
		if (interfaceId == _INTERFACE_ID_ERC2981) {
			return true;
		}
		return super.supportsInterface(interfaceId);
	}

	// Adding 99% royalty on sales via Rariable and 2981;
	function _setRoyalties(address payable _royaltyRecipient) internal nonReentrant {
		LibPart.Part[] memory _royalties = new LibPart.Part[](1);
		_royalties[0].value = royaltyBasisPoints;
		_royalties[0].account = _royaltyRecipient;
		_saveRoyalties(GoodKarmaTokenID, _royalties);
	}

	function royaltyInfo(uint256 id, uint256 _salePrice)
		public
		view
		virtual
		override(RoyaltiesV2Impl)
		returns (address receiver, uint256 royaltyAmount)
	{
		if (id != GoodKarmaTokenID) {
			// if the tokenID checked is invalid return a 0 royalty
			return (address(owner()), 0);
		}

		return super.royaltyInfo(id, _salePrice);
	}
}