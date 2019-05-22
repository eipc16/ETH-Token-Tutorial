# ETH Token

## Wymagane komponenty

- portfel na kryptowaluty (np. Metamask),
- Remix (IDE do języka Solidty - [LINK](https://remix.ethereum.org))
- npm (tworzenie projektu React, instalacja potrzebnych pakietów)

## Konfiguracja Metamask

Metamask można zainstalować pod dwiema postaciami, jako rozszerzenie do przeglądarek opartych na Chromium (Chrome, Opera) lub razem z przeglądarką Brave Browser. Obie opcje dostępne są pod adresem <https://metamask.io>. Po założeniu konta ekran główny aplikacji powinien wyglądać tak jak na poniższym zrzucie ekranu (lub podobnie).

<p align="center"> 
    <img src="https://imgur.com/CrlTp2C.png">
</p>

Jeżeli w lewym górnym rogu pojawiła się inna sieć należy ją zmienić na Rinkeby Test Net poprzez kliknięcie lewym przyciskiem myszy i wybranie odpowiedniej opcji z listy.

W celu uruchomienia naszego kontraktu na sieci Rinkeby będziemy potrzebowali Etheru, którym zapłacimy za deploy kontraktu. Darmowy Ether możemy uzyskać pod adresem <https://faucet.rinkeby.io>. Strona powinna wyglądać tak jak poniżej.

<p align="center">
    <img src="https://imgur.com/44S6J55.png" />
</p>

W celu uzyskania Etheru konieczne jest (w celach walidacyjnych) napisanie posta, w dowolnych mediach społecznościowych, który będzie zawierał adres naszego portfela. Sam adres możemy uzyskać z aplikacji Metamask poprzez kliknięcie trzech kropek przy nazwie konta i wybieraniu opcji `Copy address to clipboard`.

<p align="center">
    <img src="https://imgur.com/q13RAG5.png" />
</p>

Adres publikujemy na dowolnym serwisie społecznościowym (np. Twitter) w poniższy sposób.

<p align="center">
    <img src="https://imgur.com/0dBRjny.png" />
</p>

Następnie wybieramy opcję `Copy link to Tweet` i otrzymany adres wklejamy na stronie <https://faucet.rinkeby.io> jednocześnie wybierając dowolną z opcji po prawej stronie.

<p align="center">
    <img src="https://imgur.com/pVo4vrj.png">
</p>

Po wybraniu jednej z opcji środki powinny zostać przelane na odpowiednie konto.

## Deploy kontraktu

Każda operacja na blockchainie wykonywana jest poprzez wykorzystanie tzw. kontraktu, który definiuje wszystkie wykonywane akcje. Poniżej znajduje się kod pięciu kontraktów. Cztery z nich to kontrakty pomocnicze, natomiast ostatni jest kontraktem głównym, który zawiera wszelkie informacje o naszym kontrakcie.

### Kontrakt Safe-Math

Podstawowym celem tego kontraktu jest zapewnienie bezpiecznych operacji dodawania, odejmowania, mnożenia i dzielenia liczb z wykluczeniem możliwości wystąpienie przepełnienia.

```solidity
// Safe Math - used to deal with overflows and divide_by_zero exceptions
contract SafeMath {
    function add(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mult(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
```

### Kontrakt ERC20Interface

Poniższy kontrakt definiuje standardowy interfejs dla tokenów opartych na Ethereum. Zawiera on podstawowe metody takie jak sprawdzenie stanu konta pod podanym adresem czy przelew środków z jednego portfela na drugi.

```solidity
// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
```

### Kontrakt ApproveAndCallFallBack

Kontrakt ten zawiera funkcję wymaganą według standardu ERC20, pozwala ona aplikacjom na transfer środków z konta wydającego (po otrzymaniu zgody). 

```solidity
// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Source: MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}
```

### Kontrakt Owned

Kontrakt ten określa właściciela tokenu oraz jakie dodatkowe akcje na nim może on przeprowadzić.

```solidity
contract Owned {
    address public owner;
    address public newOwner;

    event OwnerChanged(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerChanged(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}
```

Kontruktor kontraktu zapewnia, że pierwszym właścicielem kontraktu będzie osoba, która dokonała jego deployu (sender).

```solidity
constructor() public {
    owner = msg.sender;
}
```

### Główny kontrakt tokenu (TeacheCoin)

Poniżej przedstawiony jest kod głównego kontraktu, który będzie reprezentował nasz token. W polach `<DEFAULT_ADDRESS>` wpisujemy adres portfela na które mają zostać przelane wszystkie środki (konto główne). Z konta tego możemy rozdzielić tokeny użytkownikom serwisu. Można zauważyć, że `TeacheCoin` rozszerza zdefiniowane wcześniej kontrakty `ERC20Interface`, `Owned`, `SafeMath`.

```solidity
// ----------------------------------------------------------------------------
// Teache Coin - Code
// Interfaces: ERC20Interface, Owned, SafeMath
// ----------------------------------------------------------------------------
contract TeacheCoin is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) userBalances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        symbol = "ThC";
        name = "TeacheCoin";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;
        userBalances[<DEFAULT_ADDRESS>] = _totalSupply;
        emit Transfer(address(0), <DEFAULT_ADDRESS>, _totalSupply);
    }

    // get totalSupply
    function totalSupply() public view returns (uint) {
        return _totalSupply - userBalances[address(0)];
    }

    // check balance for account tokenOwner
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return userBalances[tokenOwner];
    }

    // transfer the balance from token owner's account to the account
    // - Owner must have sufficient balance to transfer
    function transfer(address to, uint tokens) public returns (bool success) {
        userBalances[msg.sender] = sub(userBalances[msg.sender], tokens);
        userBalances[to] = add(userBalances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // Token owner can approve for spender to transferFrom(...) tokens from token owner's account
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    // Transfer tokes from one account to the other
    // - Sender's account must have sufficient balance to transfer
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        userBalances[from] = sub(userBalances[from], tokens);
        allowed[from][msg.sender] = sub(allowed[from][msg.sender], tokens);
        userBalances[to] = add(userBalances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }    

    // Returns the amount of tokens approved by the owner that can be
    // transfered to the spender's account
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // Allows token owner to approve for spender to transferFrom(...) tokens
    // from the token owner's account
    // Utilizes receiveApproval function from ApproveAndCallFallBack contract
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

    // You can't buy token with Ether
    function () external payable {
        revert();
    }

    // Allows owner to transfer out accidentally sent ERC20 Tokens
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}
```

Dwie najważniejsze części kontraktu to przedstawione poniżej mapowanie adresów, które określa balans każdego konta oraz kontruktor, w którym definiujemy główne informacje o naszym kontrakcie.

Mapowanie stanów konta do adresów.

```solidity
mapping(address => uint) userBalances;
```

Definiowanie podstawowych właśności kontraktu

```solidity
constructor() public {
    symbol = "ThC";
    name = "TeacheCoin";
    decimals = 18;
    _totalSupply = 100000000000000000000000000;
    userBalances[<DEFAULT_ADDRESS>] = _totalSupply;
    emit Transfer(address(0), <DEFAULT_ADDRESS>, _totalSupply);
}
```

W powyższym kodzie `symbol` oznacza skróconą nazwę naszego tokenu, `name` oznacza nazwę pod którą będzie on znany, natomiast pole `decimals` określa na jak małe części będzie można rozbić nasz token (standardową i zalecaną wartością jest 18). Kolejne pole `_totalSupply` określa ile tokenów jest w obiegu (nieużywane tokeny mogą być przetrzymywane na głównym koncie). W ostatnich dwóch linijkach ustawiamy stan naszego konta głównego tak, by zawierał wszystkie możliwe tokeny, a następnie wysyłamy wiadomość o transferze środków.

Na samym początku kodu definiujemy kompilator, z którego chcemy skorzystać.

```solidity
pragma solidity ^0.5.8;
```

### Przesyłanie kontraktów na blockchain

Na głównym ekranie Remix IDE wybieramy kompilator, który zostanie użyty do skompilowania kontraktów (po prawej stronie), a następnie wybieramy opcję `Start to compile`.

<p align="center">
    <img src="https://imgur.com/Apr2684.png" />
</p>

Przechodzimy do zakładki `Run` i wybieramy nasz główny kontrakt z listy (reszta kontraktów zostanie uruchomiona automatycznie). Następnie zmieniamy `Environment` na `Injected Web3` (pozwoli to na wykrycie naszego konta Metamask). Następnie klikamy w przycisk `Deploy` i zatwierdzamy dokonanie transkacji.

<p align="center">
    <img src="https://imgur.com/8oGTIas.png" />
    <img src="https://imgur.com/HtH6cO8.png" />
</p>

Po dokonaniu tych czynności powinniśmy uzyskać adres dokonanej transkacji (znajduje się on na dole ekranu w jego centralnej części).

<p align="center">
    <img src="https://imgur.com/RKT8Ep8.png" />
    <img src="https://imgur.com/mvtMFur.png" />
</p>

Na stronie transkacji klikamy w adres znajdujący się w polu `To`, a następnie przechodzimy do zakładki `Code`.

<p align="center">
    <img src="https://imgur.com/RrnxFFN.png" />
</p>

W celu weryfikacji i opublikowania naszego kontraktu klikamy w opcję `Verify and Publish`. Następnie wybieramy odpowiedni kompilator oraz jego wersję.

<p align="center">
    <img src="https://imgur.com/jjXIkpZ.png"/>
</p>

W polu `Enter the Solidity Contract Code below` wklejamy cały kod naszego kontraktu z Remix IDE, a następnie wybieramy opcję `Verify and Publish` na dole strony. Po udanej operacji zostanie wyświetlona odpowiednia strona, na dole której znajduje się pole `ContractABI`, które zawiera pozwoli nam na oddziaływanie z kontraktem na poziomie języka JavaScript.


<p align="center">
    <img src="https://imgur.com/6QB8ghV.png"/>
    <img src="https://imgur.com/6qdHyFy.png"/>
    <img src="https://imgur.com/bV7M4T8.png"/>
</p>

Zawartość pola `ContractABI` kopiujemy i umieszczamy w kodzie źródłowym naszej strony (`src/tokens/TeacheCoin.js`) w przedstawionej poniżej postaci.

```JavaScript
const Coin = {
    address: "ADRES TOKENU",
    decimal: LICZBA MIEJSC PO PRZECINKU,
    name: "NAZWA TOKENU",
    symbol: "SYMBOL TOKENU",
    abi: ZAWARTOŚĆ ContractABI
}

export default Coin;
```

Przedstawiony powyżej kod pozwoli nam na odnoszenie się do naszego kontraktu z poziomu języka JavaScript.

## Używanie kontraktu

//TODO: implementacja JS