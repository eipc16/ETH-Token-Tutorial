import React, { Component } from 'react';
import TeacheCoin from './tokens/TeacheCoin'
import './App.css';

class SendTokens extends Component {

  constructor() {
    super();

    this.state = {
      balance: 0,
      destWallet: "",
      destAmount: 0
    }

    this.isWeb3 = false;
    this.isWeb3Locked = false;

    this.loadBalance = this.loadBalance.bind(this)
    this.checkWeb3Compatibility = this.checkWeb3Compatibility.bind(this)
  }

  componentDidMount() {
    window.addEventListener('load', this.checkWeb3Compatibility)

    if (window.web3) {
        window.web3.currentProvider.publicConfigStore.on('update', () => {
            this.checkWeb3Compatibility()
        })
    }
  }

  checkWeb3Compatibility() {
      if (window.web3) {
          this.isWeb3 = true;
          window.web3.eth.getCoinbase((error, coinbase) => {
              if (error || coinbase === null) {
                  this.isWeb3Locked = true;
              } else {
                  this.isWeb3Locked = false;
                  this.setState({
                      account: coinbase,
                      token: window.web3.eth.contract(TeacheCoin.abi).at(TeacheCoin.address)
                  }, () => {
                      this.loadBalance()
                  })
              }
          })
      } else {
          this.isWeb3 = false;
      }
  }

  loadBalance() {
      if (this.isWeb3) {
          window.web3.eth.getCoinbase((error, coinbase) => {
            let token = this.state.token
            token.balanceOf(coinbase, (error, response) => {
                if (!error) {
                    let balance = response.c[0] / 10000
                    balance = balance >= 0 ? balance : 0

                    this.setState({
                        balance: balance,
                        symbol: TeacheCoin.symbol,
                        decimal: '1e' + TeacheCoin.decimal
                    })
                }
            })
          })
      }
  }

  sendTokens = (event) => {
    event.preventDefault()

    const balance = this.state.balance
    const amount = this.state.destAmount;
    const target = this.state.destWallet
    const token = this.state.token
    const decimals = this.state.decimal;

    if(amount <= balance && amount > 0 && token) {
        token.transfer(target, amount * decimals, (error, response) => {
            if(error || error !== null) {
                alert(error);
            } else {
                alert('Pomyślnie wysłano ' + amount + ' ' + this.state.symbol);
                this.loadBalance()
            }
        })
    }
  }

  handleAddressChange = (event) => {
    this.setState({
      destWallet: event.target.value
  })
  }

  handleAmountChange = (event) => {
    this.setState({
      destAmount: event.target.value
  })
  }

  render() {
    return (
      <div className="main-container">
        <p className="form-label">Stan konta</p>
        <p className="form-balance">{this.state.balance} {this.state.symbol}</p>

        <p className="form-label">Portfel odbiorcy</p>
        <input type="text" className="usr-input" onChange={e => this.handleAddressChange(e)}/>

        <p className="form-label">Liczba tokenów do wysłania</p>
        <input type="number" className="usr-input" 
              min="0" max={this.state.balance} onChange={e => this.handleAmountChange(e)} />
        <br/>
        <input type="button" className="send-btn" onClick={e => this.sendTokens(e)} value="Wyślij" /> 
      </div>
    )
  }

}

function App() {

  return (
    <div className="App">
      <SendTokens className="token-container"/>
    </div>
  );
}

export default App;
