import React, {useEffect, useRef, useState} from "react";
import NFT from "./contracts/NFT.json";
import getWeb3 from "./getWeb3";
import './dark_theme/css/mdb.dark.min.css';
import "./App.css";

const App=()=>{

  const PokemonObj = (nameID, owner, currentEnemyID) => { return { nameID: nameID, owner: owner, currentEnemyID: currentEnemyID } }
  const [web3, setWeb3] = useState();

    const [contract, setContract] = useState(null);
  const [account, setAccounts] = useState("");
  const [nameID, setNameID] = useState(0);
  const [pokemonList, setPokemonList]= useState([PokemonObj()]);
  const [enemy, setEnemy] = useState("")
  const [priceText, setPriceText] = useState("0.0000000000001");
  const [studentId, setStudentId] = useState(0);
  const [winnerPok, setWinnerPok] = useState(PokemonObj());
  
  const mint = () => {
    if (nameID.length > 0 && nameID>0) {
        contract.methods.mint(nameID).send({ from: account }, (error)=>{
        if(!error){
          let pok = PokemonObj(nameID,account);
          setPokemonList([...pokemonList, pok]);
          setNameID(0);
          // setPriceText("");
          setStudentId(pokemonList.length); // TODO read uuid from solidity programm
        }

         else {
          console.log("mint failed")
        }
      });}
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
      const abi = NFT.abi;
      const contract = new web3.eth.Contract(abi, "0x97d2cbaf09cef894c75fbb0a0695c46895a45901"); // TODO get solidity contract address
      setContract(contract);
      return contract;
  }


 useEffect(async () => {
  const web3 = await getWeb3();
  await loadWeb3Acc(web3);
  const contract = await loadWeb3Contract(web3);
  await loadNFTS(contract);
  listener(web3);
  }, [])


  
  function fight(my_uuid, enemy_uuid) {
    if(my_uuid !== undefined && enemy_uuid !== undefined) {
       const price = "0.02"
       let weiPrice = web3.utils.toWei(price, "ether")


        contract.methods.sendPokemonsToL2(my_uuid,enemy_uuid).send( {from: account, value: weiPrice} ,(error) => {
        if(error) {
          console.log(error);
        }
      });
    }
  }





 async function getWinner(contract, fightID) {
   let winnerPok_ = await contract.methods.fightIDToWinnerPokemon(3).call();
   setWinnerPok(winnerPok_)
   console.log(winnerPok_)
 }

    function listener(_web3) {

      //             topics: [null, "0x023dffb3e5bd1ebba20bf94b5fe7d6eedd205b505275353a91c7090c3d47c2d5", "0x00000000000000000000000097d2cbaf09cef894c75fbb0a0695c46895a45901", null]


        // OTHER

        var options_new = {
            fromBlock: 8047300,
            address: '0xde29d060D45901Fb19ED6C6e959EB22d8626708e', // starknetcore
            topics: [null, "0x000000000000000000000000c3511006c04ef1d78af4c8e0e74ec18a6e64ff9e", "0x073314940630fd6dcda0d772d4c972c4e0a9946bef9dabf4ef84eda8ef542b82", "0x02d757788a8d8d6f21d1cd40bce38a8222d70654214e96ff95d8086e684fbee5"]
        };
        _web3.eth.subscribe('logs', options_new,(err,event) => {
            if (!err)
                console.log(event);
        })
            .on("data", function(log) {
                console.log(log);
            })
            .on("changed", function(log) {
            });





        // var options = {
        //     fromBlock: 8047300,
        //     address: "0x97d2cbaf09cef894c75fbb0a0695c46895a45901", // our l1 contract
        //     topics: [null,"0x023dffb3e5bd1ebba20bf94b5fe7d6eedd205b505275353a91c7090c3d47c2d5"] // l2 contract
        // };
        // _web3.eth.subscribe('logs', options,(err,event) => {
        //     if (!err)
        //         console.log(event);
        // })
        //     .on("data", function(log) {
        //         console.log(log);
        //     })
        //     .on("changed", function(log) {
        //     });



    }



  return <div>
<nav className="navbar navbar-light bg-light px-4">
  <a className="navbar-brand" href="#">Crypto Pokémon</a>
  <span  className="navbar-brand" >{account}</span>
</nav>
<div className="container-fluid mt-5">
  <div className="row">
    <div className="col d-flex flex-column align-items-center">
      <div className="row-6">
      <img className="mb-4" src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/dream-world/1.svg" alt="" height="85"/>
      <img className="mb-4" src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/dream-world/4.svg" alt="" height="85"/>
      <img className="mb-4" src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/dream-world/7.svg" alt="" height="85"/>
      <img className="mb-4" src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/dream-world/25.svg" alt="" height="85"/>
      </div>
      <h1 className="display-5 fw-bold">Create your own Pokémon</h1>
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
                    <img height="150"
                         src={`https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/dream-world/${pok.nameID}.svg`}/>
                    <span>My nameID/dex# = {pok.nameID}</span>
                    <span>My UUID = {my_uuid}</span>
                    <div className="d-flex flex-row">
                        <input type="number" onWheel={(e) => e.target.blur()}
                          value={pokemonList[my_uuid].currentEnemyID}
                          onChange={
                            (e) => {

                              pokemonList[my_uuid].currentEnemyID = e.target.value // TODO possible bug: using enemy's uuid for another of your pokemon
                              console.log(pokemonList[my_uuid].currentEnemyID)

                            }

                          }
                          className="p-2"
                          placeholder="Give enemy uuid"/>
                      <button onClick={() => fight(my_uuid,pokemonList[my_uuid].currentEnemyID)} className="btn btn-primary p-2">FIGHT</button>
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
                <img height="150" src={`https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/dream-world/${student.nameID}.svg`} />
                <span>My nameID/dex# =  {student.nameID}</span>
                <span>UUID =  {index}</span>
                <span>Owner : {shortOwnerText}</span>
              </div>
          )
          }
        })
        }
      </div>
      <button onClick={() => getWinner(contract,4)}>Get winner button</button>
  </div>
  </div>
</div>
</div>;
};


export default App;
