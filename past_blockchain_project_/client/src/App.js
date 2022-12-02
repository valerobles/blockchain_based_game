import React, {useEffect, useRef, useState} from "react";
import NFT from "./contracts/NFT.json";
import getWeb3 from "./getWeb3";
import './dark_theme/css/mdb.dark.min.css';
import "./App.css";

const App = () => {

    const PokemonObj = (nameID, owner, type1, type2) => {
        return {nameID: nameID, owner: owner, type1: type1,type2: type2 }
    }
    const FightObj = (fightID, winnerID, winnerPok) => {
        return {fightID: fightID, winnerID: winnerID, PokemonObj: winnerPok}
    }
    const [web3, setWeb3] = useState();

    const [contract, setContract] = useState(null);
    const [account, setAccounts] = useState("");
    const [nameID, setNameID] = useState(0);
    const [pokemonList, setPokemonList] = useState([PokemonObj()]);
    const [fightList, setFightList] = useState([FightObj()]);
    const [currentEnemyID, setCurrentEnemyID] = useState(0);
    const typeArray = ["Normal","Fire","Water","Grass","Electric","Ice","Fight","Poison","Ground","Flying","Psychic","Bug","Rock","Ghost","Dragon","Dark","Steel","Fairy"]

    const mint = () => {
        if (nameID.length > 0 && nameID > 0) {
            contract.methods.mint(nameID).send({from: account}, (error) => {
                if (!error) {
                    let pok = PokemonObj(nameID, account);
                    setPokemonList([...pokemonList, pok]);

                } else {
                    console.log("mint failed")
                }
            });
        }
    }

    // load all the nfts
    const loadNFTS = async (contract) => {
        // get all NTFs from blockchain
        const totalSupply = await contract.methods.totalSupply().call();
        let newResults = [PokemonObj()];

        for (let i = 0; i < totalSupply; i++) {
            let pokemon = await contract.methods.pokemons(i).call();
            let newPok = (JSON.parse(JSON.stringify(pokemon))); //use json
            let pokemonToOwner = await contract.methods.ownerOf(i).call();
            let type_2 = newPok.type2 == 99? "None" : typeArray[newPok.type2];
            let newPokObj = PokemonObj(newPok.name_id, pokemonToOwner,typeArray[newPok.type1],type_2 );
            newResults.push(newPokObj);
        }
        setPokemonList(newResults);
        return true
    }

    // load web3 account from metamask
    const loadWeb3Acc = async (web3) => {
        const accounts = await web3.eth.getAccounts();
        if (accounts) {
            setWeb3(web3);
            setAccounts(accounts[0]);
        }
    }

    // load the contract
    const loadWeb3Contract = async (web3) => {
        const abi = NFT.abi;
        const contract = new web3.eth.Contract(abi, "0xb2eea57d1a4b0b07c5e4a40dea76a3c0190a7b86"); // TODO get solidity contract address
        setContract(contract);
        return contract;
    }


    useEffect(async () => {
        const web3 = await getWeb3();
        await loadWeb3Acc(web3);
        const contract = await loadWeb3Contract(web3);
        await loadNFTS(contract);

        await listener(web3, contract);


    }, [])


    function fight(my_uuid, enemy_uuid) {
        if (my_uuid !== undefined && enemy_uuid !== undefined) {
            const price = "0.02"
            let weiPrice = web3.utils.toWei(price, "ether")


            contract.methods.sendPokemonsToL2(my_uuid, enemy_uuid).send({from: account, value: weiPrice}, (error) => {
                if (error) {
                    console.log(error);
                }
            });
            setCurrentEnemyID(0);
        }
    }


    async function getWinner(contract, fightID) {
        let winnerPok_ = await contract.methods.fightIDToWinnerPokemon(3).call();
        // setWinnerPok(winnerPok_)

    }


    function listener(_web3, c) {

        var options_new = {
            fromBlock: 8047300,
            address: '0xde29d060D45901Fb19ED6C6e959EB22d8626708e', // starknetcore
            topics: [null, "0x0172cdc219c6a41e22ccdcfbfc91b86b866b9746343d55fa38931072ff205447", "0x000000000000000000000000b2eea57d1a4b0b07c5e4a40dea76a3c0190a7b86", null]
        };
        _web3.eth.subscribe('logs', options_new, (err, event) => {
            if (!err)
                console.log(event);
        })
            .on("data", function (log) {

                let temp = log.data
                let tempSub = temp.substring(temp.length - 128)
                let _winnerID = parseInt(tempSub.substring(0, 64), 16)
                let _fightID = parseInt(tempSub.substring(tempSub.length - 64), 16)
                // if (_fightID !== 3)
                createFightObj(_fightID, _winnerID, c).then(r => {
                    setFightList([...fightList, r])
                })


            })
            .on("changed", function (log) {
            });


    }

    function fightExists(fightID) {
        let fightExistsB = false
        fightList.forEach(f => {
            if (f.fightID === fightID) {
                fightExistsB = true
                console.log("exists")
            }

        })
        return fightExistsB;
    }

    async function createFightObj(fightID, w, c) {

        console.log(fightID, w)
        if (!fightExists(fightID)) {
            let pokemon = await c.methods.pokemons(w).call();
            let newPok = (JSON.parse(JSON.stringify(pokemon))); //use json
            let pokemonToOwner = await c.methods.ownerOf(w).call();
            let newPokObj = PokemonObj(newPok.name_id, pokemonToOwner);
            const fightObj = FightObj(fightID, w, newPokObj);
            fightList.push(fightObj)
            // setFightList([...fightList, FightObj(fightID, w, newPokObj)]);


            console.log("set list " + fightList.length);
            return fightObj
        }


    }


    function getTypeName(type){

    }

    let previousIndex = -1;

    return <div>
        <nav className="navbar navbar-light bg-light px-4">
            <a className="navbar-brand" href="#">Crypto Pokémon</a>
            <span className="navbar-brand">{account}</span>
        </nav>
        <div className="container-fluid mt-5">
            <div className="row">
                <div className="col d-flex flex-column align-items-center">
                    <div className="row-6">
                        <img className="mb-4"
                             src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/dream-world/1.svg"
                             alt="" height="85"/>
                        <img className="mb-4"
                             src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/dream-world/4.svg"
                             alt="" height="85"/>
                        <img className="mb-4"
                             src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/dream-world/7.svg"
                             alt="" height="85"/>
                        <img className="mb-4"
                             src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/dream-world/25.svg"
                             alt="" height="85"/>
                    </div>
                    <h1 className="display-5 fw-bold">Create your own Pokémon</h1>
                    <div className="col-6 text-center mb-3">
                        <div>
                            <input
                                type="text"
                                value={nameID}
                                onChange={(e) => setNameID(e.target.value)}
                                className="form-control mb-2"
                                placeholder="e.g. Beethoven"/>
                            <button onClick={mint} className="btn btn-primary">Mint</button>
                        </div>
                    </div>
                    <br/>
                    <br/>
                    <br/>
                    <h1>Your collection</h1>
                    <div style={{ width: "70%", overflow: "auto", display: "flex" ,justifyContent: 'center'}}>

                        {pokemonList.slice(1, pokemonList.length).map((pok, my_uuid) => {
                            if (pok.owner === account) {
                                return (
                                    <div className="d-flex flex-column align-items-center" key={my_uuid} style={{marginRight: '20px'}}>
                                        <img height="150"
                                             src={`https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/dream-world/${pok.nameID}.svg`}/>
                                        <span>My nameID/dex# = {pok.nameID}</span>
                                        <span>My UUID = {my_uuid}</span>
                                        <span>Type 1 : {pok.type1}</span>
                                        <span>Type 2 : {pok.type2}</span>
                                        <div className="d-flex flex-row">
                                            <input type="number" onWheel={(e) => e.target.blur()}
                                                   value={currentEnemyID}
                                                   onChange={
                                                       (e) => {

                                                           setCurrentEnemyID(e.target.value) // TODO possible bug: using enemy's uuid for another of your pokemon

                                                       }

                                                   }
                                                   className="p-2"
                                                   placeholder="Give enemy uuid"/>
                                            <button onClick={() => fight(my_uuid, currentEnemyID)}
                                                    className="btn btn-primary p-2">FIGHT
                                            </button>
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

                        {pokemonList.slice(1, pokemonList.length).map((pok, index) => {
                            if (pok.owner !== account) {
                                let shortOwnerText = pok.owner.substring(0, 10) + "..."
                                return (
                                    <div className="d-flex flex-column align-items-center p-4" key={index}>
                                        <img height="150"
                                             src={`https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/dream-world/${pok.nameID}.svg`}/>
                                        <span>My nameID/dex# = {pok.nameID}</span>
                                        <span>UUID = {index}</span>
                                        <span>Owner : {shortOwnerText}</span>
                                        <span>Type 1 : {pok.type1}</span>
                                        <span>Type 2 : {pok.type2}</span>
                                    </div>
                                )
                            }
                        })
                        }
                    </div>
                    <br/>
                    <br/>

                    <h1>ALL THE WINNERS</h1>
                    <div className="col-8 d-flex justify-content-center flex-wrap">
                        {
                            fightList.filter((value, index, self) =>
                                    index === self.findIndex((t) => (
                                        t.fightID === value.fightID
                                    ))
                            ).slice(1, fightList.length).map((fight, index) => {
                                let shortOwnerText = fight.PokemonObj.owner.substring(0, 10) + "..."
                                return (
                                    <div className="d-flex flex-column align-items-center p-4" key={index}>
                                        <img height="150"
                                             src={`https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/dream-world/${fight.PokemonObj.nameID}.svg`}/>
                                        <span>My nameID/dex# = {fight.PokemonObj.nameID}</span>
                                        <span>WINNER = {fight.winnerID}</span>
                                        <span>FIGHTID = {fight.fightID}</span>
                                        <span>Owner : {shortOwnerText}</span>
                                    </div>
                                )
                            })
                        }
                    </div>


                </div>
            </div>
        </div>
    </div>;
};


export default App;
