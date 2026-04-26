# Czas-do-halvingu
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title BTCHalvingCountdown
 * @dev Kontrakt obliczający czas pozostały do szacowanego halvingu BTC w 2028 roku.
 */
contract BTCHalvingCountdown {
    // Szacowana data halvingu: 22 marca 2028, 12:00:00 UTC
    // Timestamp: 1837252800 (możesz go zaktualizować przed wdrożeniem)
    uint256 public immutable targetTimestamp = 1837252800;

    /**
     * @dev Zwraca czas pozostały do halvingu w sekundach.
     * Jeśli czas już minął, zwraca 0.
     */
    function getSecondsRemaining() public view returns (uint256) {
        if (block.timestamp >= targetTimestamp) {
            return 0;
        }
        return targetTimestamp - block.timestamp;
    }

    /**
     * @dev Zwraca czytelny format: dni, godziny, minuty, sekundy.
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
