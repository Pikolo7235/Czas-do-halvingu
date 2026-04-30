// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interfejs Chainlink AggregatorV3
 */
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
    AggregatorV3Interface internal blockHeightFeed;

    // Halving 2028 nastąpi na bloku 1 050 000
    uint256 public constant HALVING_BLOCK = 1050000; 
    // Średni czas bloku BTC to 600 sekund (10 minut)
    uint256 public constant AVG_BLOCK_TIME = 600;
    // Maksymalny wiek danych z wyroczni (np. 2 godziny), aby mieć pewność, że są aktualne
    uint256 public constant HEARTBEAT_THRESHOLD = 7200; 

    constructor(address _feedAddress) {
        // Adres feedu "BTC / Block Height" z dokumentacji Chainlink
        blockHeightFeed = AggregatorV3Interface(_feedAddress);
    }

    /**
     * @dev Pobiera aktualną wysokość bloku BTC z wyroczni z walidacją danych.
     */
    function getBtcBlockHeight() public view returns (uint256) {
        (
            , 
            int256 height, 
            , 
            uint256 updatedAt, 
        ) = blockHeightFeed.latestRoundData();

        // Poprawka: Sprawdzenie poprawności i świeżości danych
        require(height > 0, "Blad danych: Wysokosc bloku ujemna");
        require(block.timestamp - updatedAt <= HEARTBEAT_THRESHOLD, "Blad danych: Odczyt jest zbyt stary");

        return uint256(height);
    }

    /**
     * @dev Szacuje sekundy pozostałe do halvingu.
     */
    function getSecondsRemaining() public view returns (uint256) {
        uint256 currentBlock = getBtcBlockHeight();
        
        if (currentBlock >= HALVING_BLOCK) {
            return 0;
        }
        
        return (HALVING_BLOCK - currentBlock) * AVG_BLOCK_TIME;
    }

    /**
     * @dev Zwraca pełne odliczanie rozbite na jednostki czasu.
     */
    function getFullCountdown() public view returns (
        uint256 daysLeft,
        uint256 hoursLeft,
        uint256 minutesLeft,
        uint256 secondsLeft
    ) {
        uint256 totalSeconds = getSecondsRemaining();

        if (totalSeconds == 0) {
            return (0, 0, 0, 0);
        }

        daysLeft = totalSeconds / 1 days;
        hoursLeft = (totalSeconds % 1 days) / 1 hours;
        minutesLeft = (totalSeconds % 1 hours) / 1 minutes;
        secondsLeft = totalSeconds % 1 minutes;
    }
}

