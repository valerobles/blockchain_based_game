import React, {useEffect, useRef, useState} from "react";
import NFT from "./contracts/NFT.json";
import getWeb3 from "./getWeb3";
// import './styles/css/styles.css';
import './dark_theme/css/mdb.dark.min.css'
import "./App.css";


const App = () => {

    const PokemonObj = (nameID, owner, type1, type2, id, name) => {
        return {nameID: nameID, owner: owner, type1: type1, type2: type2, id: id, name: name}
    }
    const FightObj = (fightID, winnerID, winnerPok, firstPok, secondPok) => {
        return {fightID: fightID, winnerID: winnerID, winnerPok: winnerPok, firstPok: firstPok, secondPok: secondPok}
    }
    const [web3, setWeb3] = useState();

    const [contract, setContract] = useState(null);
    const [account, setAccounts] = useState("");
    const [nameID, setNameID] = useState(0);
    const [pokemonList, setPokemonList] = useState([PokemonObj()]);
    const [fightList, setFightList] = useState([]);
    const typeArray = ["Normal", "Fire", "Water", "Grass", "Electric", "Ice", "Fight", "Poison", "Ground", "Flying", "Psychic", "Bug", "Rock", "Ghost", "Dragon", "Dark", "Steel", "Fairy"]

    const [mySelectedPok, setMySelectedPok] = useState(PokemonObj);
    const [oponentSelectedPok, setOponentSelectedPok] = useState(PokemonObj);
    const names = [];

    const L2_CONTRACT = "0x037ffd04fa12a5ab356e2d4d1436e2ab09cc5255373cca1d4a52feea480bf338";
    const L1_CONTRACT = "0xD4f8293b2F4Ad43E7b13974bDa74dfeb1676A442";
    const L1_CONTRACT_ZERO = "0x000000000000000000000000D4f8293b2F4Ad43E7b13974bDa74dfeb1676A442";
    const StarkNetCore = '0xde29d060D45901Fb19ED6C6e959EB22d8626708e';

    const mint = () => {
        if (nameID.length > 0 && nameID > 0) {
            contract.methods.mint(nameID).send({from: account}, (error) => {
                if (!error) {

                    let pok = PokemonObj(nameID, account,"Loading", "Loading",-1,"Loading");
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
            await getPokByUUID(i, contract).then(r => newResults.push(r))

        }
        setPokemonList(newResults);
        return true
    }

    async function getPokByUUID(uuid, contract) {
        let pokemon = await contract.methods.pokemons(uuid).call();
        let newPok = (JSON.parse(JSON.stringify(pokemon))); //use json
        let pokemonToOwner = await contract.methods.ownerOf(uuid).call();
        let type_2 = newPok.type2 == 99 ? "None" : typeArray[newPok.type2];
        let name = await getNameByIndex(newPok.name_id);
        return PokemonObj(newPok.name_id, pokemonToOwner, typeArray[newPok.type1], type_2, uuid, name);
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
        const contract = new web3.eth.Contract(abi, L1_CONTRACT); // TODO get solidity contract address
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
            setMySelectedPok(PokemonObj())
            setOponentSelectedPok(PokemonObj())
        }
    }


    async function getWinner(contract, fightID) {
        let winnerPok_ = await contract.methods.fightIDToWinnerPokemon(3).call();
        // setWinnerPok(winnerPok_)

    }


    function listener(_web3, c) {

        var options_new = {
            fromBlock: 8047300,
            address: StarkNetCore, // starknetcore
            topics: [null, L2_CONTRACT, L1_CONTRACT_ZERO, null]
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
                createFightObj(_fightID, _winnerID, c)


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

            await getPokByUUID(w, c).then(async pok => {
                let constestants = await c.methods.fightIDToFighters(fightID).call(); // call mapping in solidity contract

                let firstPok = constestants.pok1
                let secondPok = constestants.pok2
                let firstPokOwner = await c.methods.ownerOf(firstPok.id).call();
                let secondPokOwner = await c.methods.ownerOf(secondPok.id).call();

                let firstName =  await getNameByIndex(firstPok.nameID)
                let secondName = await getNameByIndex(secondPok.nameID)


                let firstType2 = firstPok.type2 == 99 ? "None" : typeArray[firstPok.type2]
                let firstPokObj = PokemonObj(firstPok.name_id, firstPokOwner, typeArray[firstPok.type1], firstType2,firstPok.id,firstName)
                let secondType2 = secondPok.type2 == 99 ? "None" : typeArray[secondPok.type2]
                let secondPokObj = PokemonObj(secondPok.name_id, secondPokOwner, typeArray[secondPok.type1], secondType2,secondPok.id, secondName)

                let fightobj = FightObj(fightID, w, pok, firstPokObj, secondPokObj)


                fightList.push(fightobj)

                setFightList(fightList.filter((value, index, self) =>
                        index === self.findIndex((t) => (
                            t.fightID === value.fightID
                        )) || value.fightID !== undefined
                ))




            });


        }


    }




    function Slideshow() {
        const delay = 2000;
        const [index, setIndex] = useState(0);
        const timeoutRef = useRef(null);

        function resetTimeout() {
            if (timeoutRef.current) {
                clearTimeout(timeoutRef.current);
            }
        }

        useEffect(() => {
            resetTimeout();
            timeoutRef.current = setTimeout(
                () =>
                    setIndex((prevIndex) =>
                        prevIndex === fightList.length - 1 ? 0 : prevIndex + 1
                    ),
                delay
            );

            return () => {
                resetTimeout();
            };
        }, [index]);

        return (
            <div className="slideshow">
                <div className="slideshowSlider" style={{transform: `translate3d(${-index * 80}%, 0, 0)`}}>
                    {fightList.map((fight, index) => {
                        let shortOwnerText = fight.winnerPok.owner.substring(0, 10) + "..."
                        return (
                            <div className="slide" key={index}>
                                <div className="d-flex flex-column align-items-center">
                                    <div className="row-10">

                                        <img height="80"
                                             src={`https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/dream-world/${fight.firstPok.nameID}.svg`}/>
                                        <span>{fight.firstPok.name}</span>
                                        <img height="80"
                                             src={`https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/dream-world/${fight.secondPok.nameID}.svg`}/>
                                        <span>{fight.secondPok.name}</span>
                                    </div>
                                    <div className="d-flex flex-column align-items-center p-4">
                                        <img height="150"
                                             src={`https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/dream-world/${fight.winnerPok.nameID}.svg`}/>
                                        <span>{fight.winnerPok.name}</span>
                                        <span>My nameID/dex# = {fight.winnerPok.nameID}</span>
                                        <span>WINNER = {fight.winnerID}</span>
                                        <span>FIGHT ID = {fight.fightID}</span>
                                        <span>Owner : {shortOwnerText}</span>
                                    </div>

                                </div>


                            </div>
                        )
                    })}


                </div>

            </div>
        );
    }


    function selectMyFighter(myPok) {
        setMySelectedPok(myPok)
    }

    function selectOtherFighter(pok) {
        setOponentSelectedPok(pok)
    }

    function showYourPok() {
        if (mySelectedPok.nameID !== undefined)
            return (
                <div className="d-flex flex-column align-items-center p-4 ">
                    <span className="font-weight-bold">Your Pokemon</span>
                    <img height="80"
                         src={`https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/dream-world/${mySelectedPok.nameID}.svg`}/>
                    <span>{mySelectedPok.name}</span>
                    <span className="corners"><div className="rcorners1">Type:</div> <div className="rcorners2">{mySelectedPok.type1} </div></span>
                    <span className="corners"><div className="rcorners1">Type:</div> <div className="rcorners2">{mySelectedPok.type2} </div></span>
                    <span>My nameID/dex# = {mySelectedPok.nameID}</span>

                </div>
            )
    }

    function showChosenOponent() {
        if (oponentSelectedPok.nameID !== undefined)
            return (
                <div className="d-flex flex-column align-items-center p-4 ">
                    <span className="font-weight-bold">Your Opponent Pokemon</span>
                    <img height="80"
                         src={`https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/dream-world/${oponentSelectedPok.nameID}.svg`}/>
                    <span>{oponentSelectedPok.name}</span>
                    <span className="corners"><div className="rcorners1">Type:</div> <div className="rcorners2">{oponentSelectedPok.type1} </div></span>
                    <span className="corners"><div className="rcorners1">Type:</div> <div className="rcorners2">{oponentSelectedPok.type2} </div></span>
                    <span>My nameID/dex# = {oponentSelectedPok.nameID}</span>

                </div>
            )
    }

    function fightButton() {
        if (oponentSelectedPok.nameID !== undefined && mySelectedPok.nameID !== undefined)
            return (
                <div className="row align-items-center" style={{width: '50%'}} >
                    <button onClick={() => fight(mySelectedPok.id, oponentSelectedPok.id)} className="btn btn-secondary p-3" style={{marginBottom: '5px',width:'50%'}}>
                        FIGHT </button>
                    <span style={{paddingTop: '10px'}}>The fight will be sent to the StarkNet platform where the fight will be calculated and later return to the Ethereum blockchain.</span>
                    <span>This usually takes 30 min to 1 hour depending on the traffic on the blockchain</span>
                    <span>Once the winner results are in, you will see it under "All the winners"</span>
                </div>



            )

    }



    const baseUrl = 'https://pokeapi.co/api/v2/pokemon/?offset='

    async function getNameByIndex(index) {
        let obj;
        const res = await fetch(baseUrl + (index - 1) + "&limit=1")
        obj = await res.json();
        let str = obj.results[0].name
        let name = str.charAt(0).toUpperCase() + str.slice(1);
        return name
    }

    return <div className="wrapper">
        <nav className="navbar navbar-light bg-light px-4">
            <a className="navbar-brand" href="#">Crypto Pokémon</a>
            <span className="navbar-brand">{account}</span>
        </nav>
        <div className="container-fluid mt-5 ">
            <div className="row ">
                <div className="col d-flex flex-column align-items-center ">
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
                    <h1 className="display-5 fw-bold" style={{width: '70%', textAlign: 'center'}}>Create your own
                        Pokémon NFT and Fight against Friends</h1>
                    <div className="col-6 text-center mb-3">
                        <div>
                            <input
                                type="text"
                                value={nameID}
                                onChange={(e) => setNameID(e.target.value)}
                                className="form-control mb-2"/>
                            <button onClick={mint} className="btn btn-primary">Mint</button>
                        </div>
                    </div>
                    <br/>
                    <div className="d-flex flex-row">
                        {showYourPok()}
                        {showChosenOponent()}

                    </div>
                    {fightButton()}


                    <br/>
                    <br/>
                    <h1>Your collection</h1>
                    <div style={{width: "70%", overflow: "auto", display: "flex"}}>

                        {pokemonList.slice(1, pokemonList.length).map((pok, my_uuid) => {
                            if (pok.owner === account) {
                                return (
                                    <div className="d-flex flex-column align-items-center p-5" key={my_uuid}
                                         style={{backgroundColor: mySelectedPok == pok ? 'darkgray' : 'transparent'}}
                                         onClick={() => selectMyFighter(pok)}>
                                        <img height="160"
                                             src={`https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/dream-world/${pok.nameID}.svg`}/>
                                        <span>{pok.name}</span>
                                        <span className="corners"><div className="rcorners1">Type:</div> <div className="rcorners2">{pok.type1} </div></span>
                                        <span className="corners"><div className="rcorners1">Type:</div> <div className="rcorners2">{pok.type2} </div></span>
                                        <span>My nameID/dex# = {pok.nameID}</span>
                                        <span>My UUID = {my_uuid}</span>
                                    </div>
                                )
                            }
                        })}

                    </div>
                    <br/>
                    <br/>
                    <br/>

                    <h1>Choose your fighter</h1>
                    <div className="col-8 d-flex justify-content-center flex-wrap">

                        {pokemonList.slice(1, pokemonList.length).map((pok, index) => {
                            if (pok.owner !== account) {
                                let shortOwnerText = pok.owner.substring(0, 10) + "..."

                                return (
                                    <div className="d-flex flex-column align-items-center p-4 " key={index}
                                         style={{backgroundColor: oponentSelectedPok == pok ? 'darkgray' : 'transparent'}}
                                         onClick={() => selectOtherFighter(pok)}>
                                        <img height="150"
                                             src={`https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/dream-world/${pok.nameID}.svg`}/>
                                        <span>{pok.name}</span>
                                        <span className="corners"><div className="rcorners1">Type:</div> <div className="rcorners2">{pok.type1} </div></span>
                                        <span className="corners"><div className="rcorners1">Type:</div> <div className="rcorners2">{pok.type2} </div></span>
                                        <span>My nameID/dex# = {pok.nameID}</span>
                                        <span>UUID = {index}</span>
                                    </div>
                                )
                            }
                        })
                        }
                    </div>
                    <br/>
                    <br/>

                    <h1>All the winners</h1>
                    {Slideshow()}


                </div>
            </div>
        </div>
    </div>;
};






export default App;
