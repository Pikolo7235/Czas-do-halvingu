// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interfejs do pobierania danych z Chainlink
interface AggregatorV3Interface {
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

contract RealBTCHalvingCountdown {
    // Adres feedu Chainlink dla BTC Block Height (przykładowy dla sieci testowej/mainnetu)
    // Uwaga: Należy sprawdzić aktualny adres w dokumentacji Chainlink dla danej sieci.
    AggregatorV3Interface internal blockHeightFeed;

    uint256 public constant HALVING_BLOCK = 1050000; // Blok halvingu w 2028 roku
    uint256 public constant AVG_BLOCK_TIME = 600;   // Średnio 600 sekund (10 minut) na blok

    constructor(address _feedAddress) {
        blockHeightFeed = AggregatorV3Interface(_feedAddress);
    }

    /**
     * @dev Pobiera aktualną wysokość bloku BTC z wyroczni.
     */
    function getBtcBlockHeight() public view returns (uint256) {
        (, int256 height, , , ) = blockHeightFeed.latestRoundData();
        return uint256(height);
    }

    /**
     * @dev Szacuje sekundy pozostałe do halvingu na podstawie brakujących bloków.
     */
    function getSecondsRemaining() public view returns (uint256) {
        uint256 currentBlock = getBtcBlockHeight();
        if (currentBlock >= HALVING_BLOCK) {
            return 0;
        }
        return (HALVING_BLOCK - currentBlock) * AVG_BLOCK_TIME;
    }

    /**
     * @dev Zwraca czytelny format odliczania.
     */
    function getFullCountdown() public view returns (
        uint256 daysLeft,
        uint256 hoursLeft,
        uint256 minutesLeft,
        uint256 secondsLeft
    ) {
        uint256 totalSeconds = getSecondsRemaining();

        daysLeft = totalSeconds / 1 days;
        hoursLeft = (totalSeconds % 1 days) / 1 hours;
        minutesLeft = (totalSeconds % 1 hours) / 1 minutes;
        secondsLeft = totalSeconds % 1 minutes;
    }
}

