import React, { useEffect, useState } from "react";
import NFT from "./contracts/NFT.json";
import getWeb3 from "./getWeb3";
import './dark_theme/css/mdb.dark.min.css';
import "./App.css";

const App=()=>{

  const PokemonObj = (nameID, owner) => { return { nameID: nameID, owner: owner } }
  const [web3, setWeb3] = useState();
  const [contract, setContract] = useState(null);
  const [account, setAccounts] = useState("");
  const [nameID, setNameID] = useState(0);
  const [pokemonList, setPokemonList]= useState([PokemonObj()]);
  const [enemy, setEnemy] = useState("")
  const [priceText, setPriceText] = useState("0.0000000000001");
  const [studentId, setStudentId] = useState(0);
  
  const mint = () => {
    if (nameID.length > 0)
      contract.methods.mint(nameID).send({ from: account }, (error)=>{
        console.log("it worked")
        if(!error){
          let pok = PokemonObj(nameID,account);
          setPokemonList([...pokemonList, pok]);
          setNameID(0);
          // setPriceText("");
          setStudentId(pokemonList.length); // TODO read uuid from solidity programm
        
        }
      });
  }

   // load all the nfts
  const loadNFTS = async (contract) => {
    // get all NTFs from blockchain
    const totalSupply = await contract.methods.totalSupply().call();
    let newResults = [PokemonObj()];

    for(let i = 0; i < totalSupply; i++){
      let pokemon = await contract.methods.pokemons(i).call();
      let newPok = (JSON.parse(JSON.stringify(pokemon))); //use json
      let pokemonToOwner = await contract.methods.ownerOf(i).call();
      let newPokObj = PokemonObj(newPok.name_id, pokemonToOwner);
      newResults.push(newPokObj);
    }
    setPokemonList(newResults);

  }

    // load web3 account from metamask
  const loadWeb3Acc = async (web3) => {
    const accounts = await web3.eth.getAccounts();
    if(accounts){
      setWeb3(web3);
      setAccounts(accounts[0]);
    }
  }

    // load the contract
  const loadWeb3Contract = async (web3) => {
    //const networkId = await web3.eth.net.getId();
    //const networkData = NFT.networks[5];
    //if(networkData){
      const abi = NFT.abi;
      // for local blockchain testing
      // const address = networkData.address;
      // const contract = new web3.eth.Contract(abi, address);
      const contract = new web3.eth.Contract(abi, "0x63a4e5e9559d1e72758216fc41e74b229a91cf42"); // TODO get solidity contract address
      setContract(contract);
      return contract;
    //}
  }


 useEffect(async () => {
  const web3 = await getWeb3();
  await loadWeb3Acc(web3);
  const contract = await loadWeb3Contract(web3);
  await loadNFTS(contract);
  }, [])


  
  function fight(my_uuid, enemy_uuid) {
    if(my_uuid !== undefined && enemy_uuid !== undefined) {
      
      contract.methods.startFight(my_uuid,enemy_uuid).send( {from: account}, (error) => {
        if(error) {
          console.log(error);
        }
      });
    }
  }

  return <div>
<nav className="navbar navbar-light bg-light px-4">
  <a className="navbar-brand" href="#">Crypto Students</a>
  <span  className="navbar-brand" >{account}</span>
</nav>
<div className="container-fluid mt-5">
  <div className="row">
    <div className="col d-flex flex-column align-items-center">
      <div className="row-6">
      <img className="mb-4" src="https://avatars.dicebear.com/api/avataaars/Welcome.svg" alt="" width="85"/>
      <img className="mb-4" src="https://avatars.dicebear.com/api/avataaars/to_the.svg" alt="" width="85"/>
      <img className="mb-4" src="https://avatars.dicebear.com/api/avataaars/best.svg" alt="" width="85"/>
      <img className="mb-4" src="https://avatars.dicebear.com/api/avataaars/NFT_Marketplace.svg" alt="" width="85"/>
      </div>
      <h1 className="display-5 fw-bold">Create your own Crypto Student NFT!</h1>
      <div className="col-6 text-center mb-3" >
        <div>
          <input
            type="text"
            value={nameID}
            onChange={(e)=>setNameID(e.target.value)}
            className="form-control mb-2"
            placeholder="e.g. Beethoven" />
          <button onClick={mint} className="btn btn-primary">Mint</button>
        </div>
      </div>
      <br/>
      <br/>
      <br/>
      <h1>Your collection</h1>
      <div className="col-8 d-flex justify-content-center flex-wrap p-4">
 
          {pokemonList.slice(1, pokemonList.length).map((pok, my_uuid) => {
            if (pok.owner === account) {
              return (
                  <div className="d-flex flex-column align-items-center" key={my_uuid}>
                    <img width="150"
                         src={`https://avatars.dicebear.com/api/avataaars/${pok.nameID}.svg`}/>
                    <span>{pok.name_id}</span>
                    <div className="d-flex flex-row">
                      <input
                          type="number"
                          value={pokemonList[my_uuid]}
                          onChange={
                            (e) =>
                                
                                setEnemy(e.target.value) // TODO possible bug: using enemy's uuid for another of your pokemon
                          }
                          className="p-2"
                          placeholder="Give enemy uuid"/>
                      <button onClick={() => fight(my_uuid,enemy)} className="btn btn-primary p-2">FIGHT</button>
                    </div>
                  </div>
              )
            }
          })}
          
      </div>
      <br/>
      <br/>
      <br/>
 
      <h1>See your friends NFTS</h1>
      <div className="col-8 d-flex justify-content-center flex-wrap">
      
        {pokemonList.slice(1, pokemonList.length).map((student, index) => {
          if ( student.owner !== account) {
            let shortOwnerText = student.owner.substring(0, 10) + "..."
            return (
              <div className="d-flex flex-column align-items-center p-4" key={index}>
                <img width="150" src={`https://avatars.dicebear.com/api/avataaars/${student.name_id}.svg`} />
                <span>{student.name_id}</span>
                <span>Owner : {shortOwnerText}</span>
              </div>
          )
          }
        })
        }
      </div>

    </div>
  </div>
</div>
</div>;
};


export default App;
