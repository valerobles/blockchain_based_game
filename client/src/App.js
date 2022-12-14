import React, {useEffect, useRef, useState} from "react";
import NFT from "./contracts/NFT.json";
import getWeb3 from "./getWeb3";
import './dark_theme/css/mdb.dark.min.css'
import "./App.css";
import eth from "./eth.png"
import starknet_logo from "./starknet.png"
import bigInt from "big-integer";


const App = () => {


    const PokemonObj = (nameID, owner, type1, type2, id, name, winCounts) => {
        return {
            nameID: nameID,
            owner: owner,
            type1: type1,
            type2: type2,
            id: id,
            name: name,
            winCounts: winCounts
        }
    }
    const FightObj = (fightID, winnerID, winnerPok, firstPok, secondPok, onBlockchain, eff_pok1, eff_pok2, blockNumber, pok1Faster) => {
        return {
            fightID: fightID,
            winnerID: winnerID,
            winnerPok: winnerPok,
            firstPok: firstPok,
            secondPok: secondPok,
            onBlockchain: onBlockchain,
            eff_pok1: eff_pok1,
            eff_pok2: eff_pok2,
            blockNumber: blockNumber,
            pok1Faster: pok1Faster
        }
    }
    const [web3, setWeb3] = useState();

    const [contract, setContract] = useState(null);
    const [account, setAccounts] = useState("");
    const [nameID, setNameID] = useState(0);
    const [pokemonList, setPokemonList] = useState([PokemonObj()]);
    const [fightList, setFightList] = useState([]);
    const typeArray = ["Normal", "Fire", "Water", "Grass", "Electric", "Ice", "Fight", "Poison", "Ground", "Flying", "Psychic", "Bug", "Rock", "Ghost", "Dragon", "Dark", "Steel", "Fairy"]

    const [mySelectedPok, setMySelectedPok] = useState(PokemonObj);
    const [opponentSelectedPok, setOpponentSelectedPok] = useState(PokemonObj);
    const [selectedFight, setSelectedFight] = useState(null);

    const L2_CONTRACT = "0x063509c6814dcf94b1b8799d4beb2004a8348289247a4f1c273bfb942ce5486f";
    const L1_CONTRACT = "0x9Ce58d716dBA650e61E12647449e470613203F37";
    const L1_CONTRACT_ZERO = "0x0000000000000000000000009Ce58d716dBA650e61E12647449e470613203F37";
    const StarkNetCore = '0xde29d060D45901Fb19ED6C6e959EB22d8626708e';

    const mint = () => {
        if (parseInt(nameID) > 0 && parseInt(nameID) < 53 && Number.isInteger(parseInt(nameID))) {
            contract.methods.mint(nameID).send({from: account}, (error) => {
                if (!error) {

                    let pok = PokemonObj(nameID, account, "Loading", "Loading", -1, "Loading", 0);
                    setPokemonList([...pokemonList, pok]);

                } else {
                    console.log("mint failed")
                }
            });
        } else {
            alert("Only numbers between 1 and 52");
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
        let type_2 = newPok.type2 === 99 ? "None" : typeArray[newPok.type2];
        let name = await getNameByIndex(newPok.name_id);
        let winCounts = await contract.methods.pokemonIDToFightsWon(uuid).call()
        return PokemonObj(newPok.name_id, pokemonToOwner, typeArray[newPok.type1], type_2, uuid, name, winCounts);
    }

    // load web3 account from metamask
    const loadWeb3Acc = async (web3) => {
        const accounts = await web3.eth.getAccounts();
        if (accounts) {
            setWeb3(web3);
            setAccounts(accounts[0]);
        }
    }

    // load the solidity contract
    const loadWeb3Contract = async (web3) => {
        const abi = NFT.abi;
        const contract = new web3.eth.Contract(abi, L1_CONTRACT);
        setContract(contract);
        return contract;
    }

    const listener_fights = async (web3,contract) => {

        const fromL2toStarkNetCore = {
            fromBlock: 8214000,
            address: StarkNetCore,
            topics: ["0x4264ac208b5fde633ccdd42e0f12c3d6d443a4f3779bbf886925b94665b63a22", L2_CONTRACT, L1_CONTRACT_ZERO, null]
        };
        web3.eth.subscribe('logs', fromL2toStarkNetCore, (err, event) => {
            if (err)
                console.log(event);
        })
            .on("data", function (log) {

                let temp = log.data

                let length = temp.length
                let size = 64
                let _winnerID = parseInt(temp.substring((length - 4 * size), (length - 3 * size)), 16)
                let _fightID = parseInt(temp.substring((length - 3 * size), (length - 2 * size)), 16)

                let _faster_eff = bigInt(temp.substring((length - 2 * size), (length - size)), 16).toString().split('').reverse().join('')
                let _slower_eff = bigInt(temp.substring((length - size), length), 16).toString().split('').reverse().join('')

                createFightObj(_fightID, _winnerID, contract, _faster_eff, _slower_eff, log.blockNumber)

            });
    }



    useEffect(() => {

        async function fetchData() {
            const web3 = await getWeb3();
            await loadWeb3Acc(web3);
            const contract = await loadWeb3Contract(web3);
            await loadNFTS(contract);

            await listener_fights(web3, contract);
        }

        fetchData();

    }, [])

    const baseUrl = 'https://pokeapi.co/api/v2/pokemon/?offset='

    async function getNameByIndex(index) {
        let obj;
        const res = await fetch(baseUrl + (index - 1) + "&limit=1")
        obj = await res.json();
        let str = obj.results[0].name
        return str.charAt(0).toUpperCase() + str.slice(1)
    }


    function fight(my_uuid, enemy_uuid) {
        if (my_uuid !== undefined && enemy_uuid !== undefined) {
            const price = "0.02"
            let weiPrice = web3.utils.toWei(price, "ether")

            contract.methods.sendPokemonsToL2(my_uuid, enemy_uuid).send({
                from: account,
                value: weiPrice
            }, (error) => {
                if (error) {
                    console.log(error);
                }
            });
            setMySelectedPok(PokemonObj())
            setOpponentSelectedPok(PokemonObj())
        }
    }


    async function saveToBlockchain(obj) {

        console.log(obj.winnerPok.id, obj.fightID)
        let eff_1 = obj.eff_pok1.reverse().toString().replaceAll(',', '')
        let eff_2 = obj.eff_pok2.reverse().toString().replaceAll(',', '')

        if (obj.pok1Faster) {
            await contract.methods.consumeMessage(obj.winnerPok.id, obj.fightID, eff_1, eff_2).send({from: account}, (error) => {
                if (error) {
                    console.log(error);
                } else {
                    obj.onBlockchain = true
                }
            });
        } else {
            await contract.methods.consumeMessage(obj.winnerPok.id, obj.fightID, eff_2, eff_1).send({from: account}, (error) => {
                if (error) {
                    console.log(error);
                } else {
                    obj.onBlockchain = true
                }
            });

        }


    }

    function selectMyFighter(myPok) {
        setMySelectedPok(myPok)
    }

    function selectOtherFighter(pok) {
        setOpponentSelectedPok(pok)
    }

    function getFight(fightObj) {
        setSelectedFight(fightObj)
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

    async function createFightObj(fightID, w, c, eff_fast, eff_slow, blocknumber) {


        if (!fightExists(fightID)) {

            await getPokByUUID(w, c).then(async pok => {


                let eff_fast_list = []

                for (let i = 0; i < eff_fast.length; i++) {
                    eff_fast_list.push(eff_fast.charAt(i))

                }

                let eff_slow_list = []

                for (let i = 0; i < eff_slow.length; i++) {
                    eff_slow_list.push(eff_slow.charAt(i))

                }
                //console.log(eff_fast_list);
                //console.log(eff_slow_list);


                let constestants = await c.methods.fightIDToFighters(fightID).call(); // call mapping in solidity contract

                let firstPok = constestants.pok1
                let secondPok = constestants.pok2
                let firstPokOwner = await c.methods.ownerOf(firstPok.id).call();
                let secondPokOwner = await c.methods.ownerOf(secondPok.id).call();

                let firstName = await getNameByIndex(firstPok.name_id)
                let secondName = await getNameByIndex(secondPok.name_id)

                let firstType2 = firstPok.type2 === 99 ? "None" : typeArray[firstPok.type2]
                let secondType2 = secondPok.type2 === 99 ? "None" : typeArray[secondPok.type2]

                let pok1Wins = await c.methods.pokemonIDToFightsWon(firstPok.id).call();
                let pok2Wins = await c.methods.pokemonIDToFightsWon(secondPok.id).call();

                let pok1_eff;
                let pok2_eff;
                let pok1WasFaster;
                if (firstPok.init > secondPok.init) {
                    pok1_eff = eff_fast_list
                    pok2_eff = eff_slow_list
                    pok1WasFaster = true;

                } else {
                    pok1_eff = eff_slow_list
                    pok2_eff = eff_fast_list
                    pok1WasFaster = false;

                }


                let firstPokObj = PokemonObj(firstPok.name_id, firstPokOwner, typeArray[firstPok.type1], firstType2, firstPok.id, firstName, pok1Wins)
                let secondPokObj = PokemonObj(secondPok.name_id, secondPokOwner, typeArray[secondPok.type1], secondType2, secondPok.id, secondName, pok2Wins)

                let fightobj = FightObj(fightID, w, pok, firstPokObj, secondPokObj, false, pok1_eff, pok2_eff, blocknumber, pok1WasFaster)

                let winnerExists = await c.methods.fightIDToWinnerPokemon(fightID).call();

                fightobj.onBlockchain = winnerExists.name_id !== '0';

                fightList.push(fightobj)

                setFightList(fightList.filter((value, index, self) =>
                        index === self.findIndex((t) => (
                            t.fightID === value.fightID
                        )) || value.fightID !== undefined
                ))


            });


        }

    }

    function showLoser(fight) {
        if (fight.firstPok.nameID === fight.winnerPok.nameID) {
            return (<div className="col-4">
                {showNameAndPicture(fight.secondPok, 80)}
                <span>{fight.secondPok.winCounts} fights won</span>
            </div>)
        } else {
            return (<div className="col-4">
                {showNameAndPicture(fight.firstPok, 80)}
                <span>{fight.firstPok.winCounts} fights won</span>
            </div>)
        }
    }

    function Slideshow() {
        const delay = 4000;
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
                            <div className="slide" key={index} onClick={() => getFight(fight)}>

                                <div className="d-flex flex-column align-items-center p-4">
                                    {showNameAndPicture(fight.winnerPok, 150)}
                                    <span>{fight.winnerPok.winCounts} fights won</span>
                                    <span>Fight-ID: {fight.fightID}</span>
                                    <span>Owner: {shortOwnerText}</span>
                                    <span className="font-weight-bold">Won vs.</span>
                                    {showLoser(fight)}
                                    <span>Blocknumber: {fight.blockNumber}</span>
                                    {isOnBlockchainMessage(fight)}
                                </div>





                    </div>
                    )
                    })}


                </div>

            </div>
        );
    }


    function showYourPok() {
        if (mySelectedPok.nameID !== undefined) {
            return (
                <div className="d-flex flex-column align-items-center p-4">
                    <span className="font-weight-bold">Your Fighter</span>
                    {showNameAndPicture(mySelectedPok, 110)}
                    {showTypes(mySelectedPok)}
                </div>
            )
        }
    }

    function showNameAndPicture(pok, height) {
        return (<div className="d-flex flex-column align-items-center ">
                <span className="textName">{pok.name} #{pok.nameID}</span>
                <br/>
                <img alt="" height={height}
                     src={`https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/dream-world/${pok.nameID}.svg`}/>
            </div>
        )
    }

    function showTypes(pok) {
        if (pok.type2 !== 'None' && pok.type2 !== undefined) {
            return (
                <div>
                <span className="corners"><div className="rcorners1">Type:</div> <div
                    className="rcorners2">{pok.type1} </div></span>
                    <span className="corners"><div className="rcorners1">Type:</div> <div
                        className="rcorners2">{pok.type2} </div></span>
                </div>
            )
        } else {
            return (<div>
            <span className="corners"><div className="rcorners1">Type:</div> <div
                className="rcorners2">{pok.type1} </div></span>
            </div>)
        }
    }

    function showChosenOponent() {
        if (opponentSelectedPok.nameID !== undefined)
            return (
                <div className="d-flex flex-column align-items-center p-4 ">
                    <span className="font-weight-bold">Opponent</span>
                    {showNameAndPicture(opponentSelectedPok, 110)}
                    {showTypes(opponentSelectedPok)}
                </div>
            )
    }

    function fightButton() {
        if (mySelectedPok.nameID !== undefined && opponentSelectedPok.nameID !== undefined)
            return (
                <div style={{height: '100%', width: '100%'}}>
                    <div style={{height: '40%'}}></div>
                    <button onClick={() => fight(mySelectedPok.id, opponentSelectedPok.id)}
                            className="btn btn-secondary p-2 " style={{
                        width: '100%', height: '20%'

                    }}>
                        FIGHT
                    </button>
                </div>


            )

    }


    function showRounds() {
        if (selectedFight != null) {
            return (
                <div>
                    <span>Efficiency pok 1 {selectedFight.eff_pok1}</span>
                    <br/>
                    <span>Efficiency pok 2 {selectedFight.eff_pok2}</span>
                </div>
            )
        }

    }


    function isOnBlockchainMessage(fightOb) {
        if (fightOb.onBlockchain) {
            return (
                <p>Is saved forever on Ethereum blockchain</p>

            )
        } else {
            return (
                <button className="btn btn-black p-2" onClick={() => saveToBlockchain(fightOb)}>Save results on
                    blockchain</button>
            )

        }

    }

    return <div>
        <div className="navbar navbar-light bg-light px-4">
            <div className="navbar-brand">Crypto Pok??mon</div>
            <span className="navbar-brand">{account}</span>
        </div>
        <div className="container-fluid mt-5 ">
            <div className="row ">
                <div className="col d-flex flex-column align-items-center ">
                    <div className="row-7">
                        <img alt="" className="mb-4" style={{padding: '10px'}}
                             src={eth}
                             height="60"/>
                        <img alt="0" className="mb-4"
                             src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/dream-world/1.svg"
                             height="85"/>
                        <img alt="" className="mb-4"
                             src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/dream-world/4.svg"
                             height="85"/>
                        <img alt="" className="mb-4"
                             src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/dream-world/7.svg"
                             height="85"/>
                        <img alt="" className="mb-4"
                             src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/dream-world/25.svg"
                             height="85"/>
                        <img alt="" className="mb-4" style={{padding: '10px'}}
                             src={eth}
                             height="60"/>
                    </div>
                    <h2 className="display-7 fw-bold"
                        style={{width: '70%', textAlign: 'center', marginBottom: '150px'}}>Create your own
                        Pok??mon NFT and fight against friends on the Ethereum blockchain using ZK-Rollups on <a
                            href="https://starkware.co/starknet/">StarkNet*</a></h2>
                    <div className="col-6 text-center mb-3">
                        <h3>Mint your pokemon <img alt="" src={eth} height="30"/></h3>
                        <span>Choose a Pokemon dex number from 1 to 52 </span> <br/>
                        <span>See which <a href={"https://www.pokemon.com/us/pokedex"}>Pokemon</a> you can choose from</span>
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
                        {fightButton()}
                        {showChosenOponent()}

                    </div>


                    <br/>
                    <br/>
                    <h1>Your collection</h1>
                    <p>Select a Pokemon to fight</p>
                    <div style={{width: "70%", overflow: "auto", display: "flex", height: "800px"}}>

                        {pokemonList.slice(1, pokemonList.length).map((pok, my_uuid) => {
                            if (pok.owner === account) {
                                return (
                                    <div className="d-flex flex-column align-items-center p-6" key={my_uuid}
                                         style={{
                                             backgroundColor: mySelectedPok === pok ? 'darkgray' : 'transparent',
                                             height: '100%'
                                         }}
                                         onClick={() => selectMyFighter(pok)}>
                                        {showNameAndPicture(pok, 160)}
                                        {showTypes(pok)}
                                        <span>Wins: {pok.winCounts}</span>
                                        <span>ID: {my_uuid}</span>
                                    </div>
                                )
                            } else {
                                return ("")
                            }
                        })}

                    </div>
                    <br/>
                    <br/>
                    <br/>

                    <h1>Choose your opponent</h1>
                    <div className="col-8 d-flex justify-content-center flex-wrap">

                        {pokemonList.slice(1, pokemonList.length).map((pok, index) => {
                            if (pok.owner !== account) {
                                return (
                                    <div className="d-flex flex-column align-items-center p-4 " key={index}
                                         style={{backgroundColor: opponentSelectedPok === pok ? 'darkgray' : 'transparent'}}
                                         onClick={() => selectOtherFighter(pok)}>
                                        {showNameAndPicture(pok, 150)}
                                        {showTypes(pok)}
                                        <span>Wins: {pok.winCounts}</span>
                                        <span>ID: {index}</span>
                                    </div>
                                )
                            } else {
                                return ("")
                            }
                        })
                        }
                    </div>
                    <br/>
                    <br/>

                    <h1>All the winners</h1>
                    <p>Fresh out of StarkNet <img alt="" src={starknet_logo} height="30px"/></p>
                    {Slideshow()}
                    {showRounds()}
                    <h1>About this project</h1>
                    <div style={{alignItems: 'center', display: 'flex', flexDirection: 'column'}}>
                        <div style={{backgroundColor: '#4a5772', width: '70%', padding: '20px'}}>
                            <br/>
                            <span>A Fight between two Pokemon will be sent to the StarkNet platform where the fight will be calculated and later return to the Ethereum blockchain.</span>
                            <span>This usually takes 30 min to 1 hour depending on the traffic on the blockchain</span>
                            <span>Once the winner results are in, you will see it under "All the winners"</span>
                            <span>To save the results on the blockchain and have your Pokemon's wins update, click on "Save results to blockchain". This is a transaction and gas fees must be paid. </span>
                            <span>The transaction takes around 2 minutes to be confirmed.</span>
                        </div>
                        <br/>
                        <div style={{backgroundColor: '#5c4a72', width: '70%', padding: '20px'}}>
                            <br/>
                            <span> MORE INFO? </span>

                        </div>
                    </div>

                </div>
                <div className="footer">
                    <p style={{color: "black"}}>Project by Luca Lunati and Valeria Robles Garzon for FHNW</p>
                </div>
            </div>

        </div>

    </div>;
};


export default App;
