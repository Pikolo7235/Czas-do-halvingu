const { ethers } = require("ethers");

// 1. Konfiguracja
const RPC_URL = "TWOJ_URL_RPC_NP_ALCHEMY_LUB_INFURA"; // Ethereum Mainnet
const CONTRACT_ADDRESS = "ADRES_TWOJEGO_WDROZONEGO_KONTRAKTU";

// 2. ABI - wystarczy tylko funkcja, którą wywołujemy
const ABI = [
    "function getFormattedCountdown() view returns (tuple(uint256 totalSeconds, uint256 daysLeft, uint256 hoursLeft, uint256 minutesLeft, uint256 secondsLeft, uint256 currentBtcBlock))"
];

async function getHalvingData() {
    try {
        // Połączenie z siecią
        const provider = new ethers.JsonRpcProvider(RPC_URL);
        const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, provider);

        console.log("Pobieranie danych z kontraktu...");
        
        // Wywołanie funkcji (zwraca obiekt zgodny ze strukturą Countdown)
        const data = await contract.getFormattedCountdown();

        // 3. Wyświetlenie wyników
        console.log("------------------------------------------");
        console.log(`Aktualny blok BTC: ${data.currentBtcBlock}`);
        console.log(`Do halvingu pozostało:`);
        console.log(`${data.daysLeft} dni, ${data.hoursLeft}h, ${data.minutesLeft}m, ${data.secondsLeft}s`);
        console.log(`Łącznie sekund: ${data.totalSeconds}`);
        console.log("------------------------------------------");

        if (data.totalSeconds == 0) {
            console.log("Halving już się odbył! 🎉");
        }

    } catch (error) {
        console.error("Błąd podczas pobierania danych:", error.message);
    }
}

getHalvingData();
