// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
/* 
Smart Contract Programmer Solidity 0.8 Dutch Auction video codes explained in Turkish by 0xabd for educational purposes.
For original content: https://www.youtube.com/watch?v=Ykt2Wqt6pBQ&list=PLO5VPQH6OWdVQwpQfw9rZ67O6Pjfo6q-p&index=58

*/

interface IERC721{ // Bir NFT satışı yapacağımız için NFT'ler için kullanılan ERC721 interface'ini kullanıyoruz.
    function transferFrom( // Şimdilik sadece satış yapacağımız için transferFrom fonksiyonunu almamız bizim icin yeterli olacaktir.
        address _from,
        address _to,
        uint _nftId // transfer edilecek NFT'nin id'si: 1000 adet NFT varsa id'ler 0dan başlar ve 999'de biter gibi. Bu örnekte bu id'yi rastgele vereceğiz.
    ) external;
}


contract DutchAuction {
    uint private constant DURATION = 7 days; // Açık arttırmanın ne kadar süreceğini belirliyoruz.
    IERC721 public immutable nft; // NFT degiskenimizi oluşturuyoruz.
    uint public immutable nftId; // NFT id degiskenimizi oluşturuyoruz
    // immutable ile constant arasındaki fark: immutable degiskenleri constructer icerinde tanımlarsınız ve sonrasında degisteremezsiniz. (constant gibi)
    address payable public immutable seller; // Satan kişinin adresi
    uint public immutable startingPrice; // Açık arttırmanın başlayacağı fiyat.
    uint public immutable startAt;  // Açık arttırmanın ne zaman başlayacağı
    uint public immutable expiresAt; // Açık arttırmanın ne zaman biteceği
    uint public immutable discountRate; // Her geçen zamanda fiyatın ne kadar düşeceği.

    constructor( // constructor icerisinde tum immutable degiskenleri tanimlamak zorundayiz.
    // Bu 4 degiskeni disaridan veriyoruz.
        uint _startingPrice,
        uint _discountRate,
        address _nft,
        uint _nftId
    ){
        seller = payable(msg.sender); 
        startingPrice = _startingPrice;
        discountRate = _discountRate;
        startAt = block.timestamp; // contract deploy edildigi an açık arttirma baslar.
        expiresAt = startAt + DURATION; // baslangic + 7 gun icerisinde biter.
        require(_startingPrice >= _discountRate *DURATION, "starting price < min");

        nft = IERC721(_nft);
        nftId = _nftId;
    }
    // alicilarin almadan once fiyati kontrol etmesini saglayan fonksiyon
    function getPrice() public view returns(uint price) {
        uint timeElapsed = block.timestamp - startAt; // gecen zamanin hesaplanmasi
        uint discount = discountRate * timeElapsed; // indirimin hesaplanmasi
        price = startingPrice - discount; // guncel fiyatin hesaplanmasi
    }
    // satın alma ve transfer islemlerinin gerceklestigi fonksiyon
    function buy() external payable {
        require(block.timestamp < expiresAt, "auction expired");
        uint price  = getPrice();
        require(msg.value >= price, "ETH < price");
        nft.transferFrom(seller, msg.sender, nftId);
        uint refund = msg.value - price; // eger alici fiyattan daha fazla ether gondermisse fazlasini iade ediyoruz.
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
        selfdestruct(seller); // açık arttırma oldugu icin item satildiktan sonra acik arttirmanin bitmesi gerekir.
        // burada da bunu selfdestruct ile yapiyoruz. Selfdestruct contracti siler ve icerisindeki etherleri verilen address'e gonderir. Burada da o adress satici oluyor.
    }


}
