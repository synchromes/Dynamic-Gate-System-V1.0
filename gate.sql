-- phpMyAdmin SQL Dump
-- version 5.0.4
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Waktu pembuatan: 04 Bulan Mei 2021 pada 14.45
-- Versi server: 10.4.17-MariaDB
-- Versi PHP: 8.0.2

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `mgrp`
--

-- --------------------------------------------------------

--
-- Struktur dari tabel `gate`
--

CREATE TABLE `gate` (
  `gid` int(11) NOT NULL,
  `gstatus` int(11) NOT NULL,
  `gmodel` int(11) NOT NULL,
  `gspeed` float NOT NULL,
  `grange` float NOT NULL,
  `gowner` int(11) NOT NULL,
  `gownername` varchar(24) NOT NULL,
  `gmcmd` int(11) NOT NULL,
  `gmhorn` int(11) NOT NULL,
  `gmfoot` int(11) NOT NULL,
  `gmveh` int(11) NOT NULL,
  `gclosex` float NOT NULL,
  `gclosey` float NOT NULL,
  `gclosez` float NOT NULL,
  `gcloserx` float NOT NULL,
  `gclosery` float NOT NULL,
  `gcloserz` float NOT NULL,
  `gopenx` float NOT NULL,
  `gopeny` float NOT NULL,
  `gopenz` float NOT NULL,
  `gopenrx` float NOT NULL,
  `gopenry` float NOT NULL,
  `gopenrz` float NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Indexes for dumped tables
--

--
-- Indeks untuk tabel `gate`
--
ALTER TABLE `gate`
  ADD PRIMARY KEY (`gid`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
