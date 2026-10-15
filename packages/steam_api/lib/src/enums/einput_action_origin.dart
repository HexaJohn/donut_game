// ignore_for_file: public_member_api_docs, always_specify_types, avoid_positional_boolean_parameters, avoid_classes_with_only_static_members, unreachable_switch_case
import "dart:ffi";
import "../unknown_enum_value_exception.dart";

typedef EInputActionOriginAliasDart = int;
typedef EInputActionOriginAliasC = Int32;

enum EInputActionOrigin {
  none(0),
  steamControllerA(1),
  steamControllerB(2),
  steamControllerX(3),
  steamControllerY(4),
  steamControllerLeftBumper(5),
  steamControllerRightBumper(6),
  steamControllerLeftGrip(7),
  steamControllerRightGrip(8),
  steamControllerStart(9),
  steamControllerBack(10),
  steamControllerLeftPadTouch(11),
  steamControllerLeftPadSwipe(12),
  steamControllerLeftPadClick(13),
  steamControllerLeftPadDPadNorth(14),
  steamControllerLeftPadDPadSouth(15),
  steamControllerLeftPadDPadWest(16),
  steamControllerLeftPadDPadEast(17),
  steamControllerRightPadTouch(18),
  steamControllerRightPadSwipe(19),
  steamControllerRightPadClick(20),
  steamControllerRightPadDPadNorth(21),
  steamControllerRightPadDPadSouth(22),
  steamControllerRightPadDPadWest(23),
  steamControllerRightPadDPadEast(24),
  steamControllerLeftTriggerPull(25),
  steamControllerLeftTriggerClick(26),
  steamControllerRightTriggerPull(27),
  steamControllerRightTriggerClick(28),
  steamControllerLeftStickMove(29),
  steamControllerLeftStickClick(30),
  steamControllerLeftStickDPadNorth(31),
  steamControllerLeftStickDPadSouth(32),
  steamControllerLeftStickDPadWest(33),
  steamControllerLeftStickDPadEast(34),
  steamControllerGyroMove(35),
  steamControllerGyroPitch(36),
  steamControllerGyroYaw(37),
  steamControllerGyroRoll(38),
  steamControllerReserved0(39),
  steamControllerReserved1(40),
  steamControllerReserved2(41),
  steamControllerReserved3(42),
  steamControllerReserved4(43),
  steamControllerReserved5(44),
  steamControllerReserved6(45),
  steamControllerReserved7(46),
  steamControllerReserved8(47),
  steamControllerReserved9(48),
  steamControllerReserved10(49),
  ps4X(50),
  ps4Circle(51),
  ps4Triangle(52),
  ps4Square(53),
  ps4LeftBumper(54),
  ps4RightBumper(55),
  ps4Options(56),
  ps4Share(57),
  ps4LeftPadTouch(58),
  ps4LeftPadSwipe(59),
  ps4LeftPadClick(60),
  ps4LeftPadDPadNorth(61),
  ps4LeftPadDPadSouth(62),
  ps4LeftPadDPadWest(63),
  ps4LeftPadDPadEast(64),
  ps4RightPadTouch(65),
  ps4RightPadSwipe(66),
  ps4RightPadClick(67),
  ps4RightPadDPadNorth(68),
  ps4RightPadDPadSouth(69),
  ps4RightPadDPadWest(70),
  ps4RightPadDPadEast(71),
  ps4CenterPadTouch(72),
  ps4CenterPadSwipe(73),
  ps4CenterPadClick(74),
  ps4CenterPadDPadNorth(75),
  ps4CenterPadDPadSouth(76),
  ps4CenterPadDPadWest(77),
  ps4CenterPadDPadEast(78),
  ps4LeftTriggerPull(79),
  ps4LeftTriggerClick(80),
  ps4RightTriggerPull(81),
  ps4RightTriggerClick(82),
  ps4LeftStickMove(83),
  ps4LeftStickClick(84),
  ps4LeftStickDPadNorth(85),
  ps4LeftStickDPadSouth(86),
  ps4LeftStickDPadWest(87),
  ps4LeftStickDPadEast(88),
  ps4RightStickMove(89),
  ps4RightStickClick(90),
  ps4RightStickDPadNorth(91),
  ps4RightStickDPadSouth(92),
  ps4RightStickDPadWest(93),
  ps4RightStickDPadEast(94),
  ps4DPadNorth(95),
  ps4DPadSouth(96),
  ps4DPadWest(97),
  ps4DPadEast(98),
  ps4GyroMove(99),
  ps4GyroPitch(100),
  ps4GyroYaw(101),
  ps4GyroRoll(102),
  ps4DPadMove(103),
  ps4Reserved1(104),
  ps4Reserved2(105),
  ps4Reserved3(106),
  ps4Reserved4(107),
  ps4Reserved5(108),
  ps4Reserved6(109),
  ps4Reserved7(110),
  ps4Reserved8(111),
  ps4Reserved9(112),
  ps4Reserved10(113),
  xBoxOneA(114),
  xBoxOneB(115),
  xBoxOneX(116),
  xBoxOneY(117),
  xBoxOneLeftBumper(118),
  xBoxOneRightBumper(119),
  xBoxOneMenu(120),
  xBoxOneView(121),
  xBoxOneLeftTriggerPull(122),
  xBoxOneLeftTriggerClick(123),
  xBoxOneRightTriggerPull(124),
  xBoxOneRightTriggerClick(125),
  xBoxOneLeftStickMove(126),
  xBoxOneLeftStickClick(127),
  xBoxOneLeftStickDPadNorth(128),
  xBoxOneLeftStickDPadSouth(129),
  xBoxOneLeftStickDPadWest(130),
  xBoxOneLeftStickDPadEast(131),
  xBoxOneRightStickMove(132),
  xBoxOneRightStickClick(133),
  xBoxOneRightStickDPadNorth(134),
  xBoxOneRightStickDPadSouth(135),
  xBoxOneRightStickDPadWest(136),
  xBoxOneRightStickDPadEast(137),
  xBoxOneDPadNorth(138),
  xBoxOneDPadSouth(139),
  xBoxOneDPadWest(140),
  xBoxOneDPadEast(141),
  xBoxOneDPadMove(142),
  xBoxOneLeftGripLower(143),
  xBoxOneLeftGripUpper(144),
  xBoxOneRightGripLower(145),
  xBoxOneRightGripUpper(146),
  xBoxOneShare(147),
  xBoxOneReserved6(148),
  xBoxOneReserved7(149),
  xBoxOneReserved8(150),
  xBoxOneReserved9(151),
  xBoxOneReserved10(152),
  xBox360A(153),
  xBox360B(154),
  xBox360X(155),
  xBox360Y(156),
  xBox360LeftBumper(157),
  xBox360RightBumper(158),
  xBox360Start(159),
  xBox360Back(160),
  xBox360LeftTriggerPull(161),
  xBox360LeftTriggerClick(162),
  xBox360RightTriggerPull(163),
  xBox360RightTriggerClick(164),
  xBox360LeftStickMove(165),
  xBox360LeftStickClick(166),
  xBox360LeftStickDPadNorth(167),
  xBox360LeftStickDPadSouth(168),
  xBox360LeftStickDPadWest(169),
  xBox360LeftStickDPadEast(170),
  xBox360RightStickMove(171),
  xBox360RightStickClick(172),
  xBox360RightStickDPadNorth(173),
  xBox360RightStickDPadSouth(174),
  xBox360RightStickDPadWest(175),
  xBox360RightStickDPadEast(176),
  xBox360DPadNorth(177),
  xBox360DPadSouth(178),
  xBox360DPadWest(179),
  xBox360DPadEast(180),
  xBox360DPadMove(181),
  xBox360Reserved1(182),
  xBox360Reserved2(183),
  xBox360Reserved3(184),
  xBox360Reserved4(185),
  xBox360Reserved5(186),
  xBox360Reserved6(187),
  xBox360Reserved7(188),
  xBox360Reserved8(189),
  xBox360Reserved9(190),
  xBox360Reserved10(191),
  switchA(192),
  switchB(193),
  switchX(194),
  switchY(195),
  switchLeftBumper(196),
  switchRightBumper(197),
  switchPlus(198),
  switchMinus(199),
  switchCapture(200),
  switchLeftTriggerPull(201),
  switchLeftTriggerClick(202),
  switchRightTriggerPull(203),
  switchRightTriggerClick(204),
  switchLeftStickMove(205),
  switchLeftStickClick(206),
  switchLeftStickDPadNorth(207),
  switchLeftStickDPadSouth(208),
  switchLeftStickDPadWest(209),
  switchLeftStickDPadEast(210),
  switchRightStickMove(211),
  switchRightStickClick(212),
  switchRightStickDPadNorth(213),
  switchRightStickDPadSouth(214),
  switchRightStickDPadWest(215),
  switchRightStickDPadEast(216),
  switchDPadNorth(217),
  switchDPadSouth(218),
  switchDPadWest(219),
  switchDPadEast(220),
  switchProGyroMove(221),
  switchProGyroPitch(222),
  switchProGyroYaw(223),
  switchProGyroRoll(224),
  switchDPadMove(225),
  switchReserved1(226),
  switchReserved2(227),
  switchReserved3(228),
  switchReserved4(229),
  switchReserved5(230),
  switchReserved6(231),
  switchReserved7(232),
  switchReserved8(233),
  switchReserved9(234),
  switchReserved10(235),
  switchRightGyroMove(236),
  switchRightGyroPitch(237),
  switchRightGyroYaw(238),
  switchRightGyroRoll(239),
  switchLeftGyroMove(240),
  switchLeftGyroPitch(241),
  switchLeftGyroYaw(242),
  switchLeftGyroRoll(243),
  switchLeftGripLower(244),
  switchLeftGripUpper(245),
  switchRightGripLower(246),
  switchRightGripUpper(247),
  switchJoyConButtonN(248),
  switchJoyConButtonE(249),
  switchJoyConButtonS(250),
  switchJoyConButtonW(251),
  switchReserved15(252),
  switchReserved16(253),
  switchReserved17(254),
  switchReserved18(255),
  switchReserved19(256),
  switchReserved20(257),
  ps5X(258),
  ps5Circle(259),
  ps5Triangle(260),
  ps5Square(261),
  ps5LeftBumper(262),
  ps5RightBumper(263),
  ps5Option(264),
  ps5Create(265),
  ps5Mute(266),
  ps5LeftPadTouch(267),
  ps5LeftPadSwipe(268),
  ps5LeftPadClick(269),
  ps5LeftPadDPadNorth(270),
  ps5LeftPadDPadSouth(271),
  ps5LeftPadDPadWest(272),
  ps5LeftPadDPadEast(273),
  ps5RightPadTouch(274),
  ps5RightPadSwipe(275),
  ps5RightPadClick(276),
  ps5RightPadDPadNorth(277),
  ps5RightPadDPadSouth(278),
  ps5RightPadDPadWest(279),
  ps5RightPadDPadEast(280),
  ps5CenterPadTouch(281),
  ps5CenterPadSwipe(282),
  ps5CenterPadClick(283),
  ps5CenterPadDPadNorth(284),
  ps5CenterPadDPadSouth(285),
  ps5CenterPadDPadWest(286),
  ps5CenterPadDPadEast(287),
  ps5LeftTriggerPull(288),
  ps5LeftTriggerClick(289),
  ps5RightTriggerPull(290),
  ps5RightTriggerClick(291),
  ps5LeftStickMove(292),
  ps5LeftStickClick(293),
  ps5LeftStickDPadNorth(294),
  ps5LeftStickDPadSouth(295),
  ps5LeftStickDPadWest(296),
  ps5LeftStickDPadEast(297),
  ps5RightStickMove(298),
  ps5RightStickClick(299),
  ps5RightStickDPadNorth(300),
  ps5RightStickDPadSouth(301),
  ps5RightStickDPadWest(302),
  ps5RightStickDPadEast(303),
  ps5DPadNorth(304),
  ps5DPadSouth(305),
  ps5DPadWest(306),
  ps5DPadEast(307),
  ps5GyroMove(308),
  ps5GyroPitch(309),
  ps5GyroYaw(310),
  ps5GyroRoll(311),
  ps5DPadMove(312),
  ps5LeftGrip(313),
  ps5RightGrip(314),
  ps5LeftFn(315),
  ps5RightFn(316),
  ps5Reserved5(317),
  ps5Reserved6(318),
  ps5Reserved7(319),
  ps5Reserved8(320),
  ps5Reserved9(321),
  ps5Reserved10(322),
  ps5Reserved11(323),
  ps5Reserved12(324),
  ps5Reserved13(325),
  ps5Reserved14(326),
  ps5Reserved15(327),
  ps5Reserved16(328),
  ps5Reserved17(329),
  ps5Reserved18(330),
  ps5Reserved19(331),
  ps5Reserved20(332),
  steamDeckA(333),
  steamDeckB(334),
  steamDeckX(335),
  steamDeckY(336),
  steamDeckL1(337),
  steamDeckR1(338),
  steamDeckMenu(339),
  steamDeckView(340),
  steamDeckLeftPadTouch(341),
  steamDeckLeftPadSwipe(342),
  steamDeckLeftPadClick(343),
  steamDeckLeftPadDPadNorth(344),
  steamDeckLeftPadDPadSouth(345),
  steamDeckLeftPadDPadWest(346),
  steamDeckLeftPadDPadEast(347),
  steamDeckRightPadTouch(348),
  steamDeckRightPadSwipe(349),
  steamDeckRightPadClick(350),
  steamDeckRightPadDPadNorth(351),
  steamDeckRightPadDPadSouth(352),
  steamDeckRightPadDPadWest(353),
  steamDeckRightPadDPadEast(354),
  steamDeckL2SoftPull(355),
  steamDeckL2(356),
  steamDeckR2SoftPull(357),
  steamDeckR2(358),
  steamDeckLeftStickMove(359),
  steamDeckL3(360),
  steamDeckLeftStickDPadNorth(361),
  steamDeckLeftStickDPadSouth(362),
  steamDeckLeftStickDPadWest(363),
  steamDeckLeftStickDPadEast(364),
  steamDeckLeftStickTouch(365),
  steamDeckRightStickMove(366),
  steamDeckR3(367),
  steamDeckRightStickDPadNorth(368),
  steamDeckRightStickDPadSouth(369),
  steamDeckRightStickDPadWest(370),
  steamDeckRightStickDPadEast(371),
  steamDeckRightStickTouch(372),
  steamDeckL4(373),
  steamDeckR4(374),
  steamDeckL5(375),
  steamDeckR5(376),
  steamDeckDPadMove(377),
  steamDeckDPadNorth(378),
  steamDeckDPadSouth(379),
  steamDeckDPadWest(380),
  steamDeckDPadEast(381),
  steamDeckGyroMove(382),
  steamDeckGyroPitch(383),
  steamDeckGyroYaw(384),
  steamDeckGyroRoll(385),
  steamDeckReserved1(386),
  steamDeckReserved2(387),
  steamDeckReserved3(388),
  steamDeckReserved4(389),
  steamDeckReserved5(390),
  steamDeckReserved6(391),
  steamDeckReserved7(392),
  steamDeckReserved8(393),
  steamDeckReserved9(394),
  steamDeckReserved10(395),
  steamDeckReserved11(396),
  steamDeckReserved12(397),
  steamDeckReserved13(398),
  steamDeckReserved14(399),
  steamDeckReserved15(400),
  steamDeckReserved16(401),
  steamDeckReserved17(402),
  steamDeckReserved18(403),
  steamDeckReserved19(404),
  steamDeckReserved20(405),
  horipadM1(406),
  horipadM2(407),
  horipadL4(408),
  horipadR4(409),
  lenovoLegionGoA(410),
  lenovoLegionGoB(411),
  lenovoLegionGoX(412),
  lenovoLegionGoY(413),
  lenovoLegionGoLB(414),
  lenovoLegionGoRB(415),
  lenovoLegionGoMenu(416),
  lenovoLegionGoView(417),
  lenovoLegionGoLeftPadTouch(418),
  lenovoLegionGoLeftPadSwipe(419),
  lenovoLegionGoLeftPadClick(420),
  lenovoLegionGoLeftPadDPadNorth(421),
  lenovoLegionGoLeftPadDPadSouth(422),
  lenovoLegionGoLeftPadDPadWest(423),
  lenovoLegionGoLeftPadDPadEast(424),
  lenovoLegionGoRightPadTouch(425),
  lenovoLegionGoRightPadSwipe(426),
  lenovoLegionGoRightPadClick(427),
  lenovoLegionGoRightPadDPadNorth(428),
  lenovoLegionGoRightPadDPadSouth(429),
  lenovoLegionGoRightPadDPadWest(430),
  lenovoLegionGoRightPadDPadEast(431),
  lenovoLegionGoLTSoftPull(432),
  lenovoLegionGoLT(433),
  lenovoLegionGoRTSoftPull(434),
  lenovoLegionGoRT(435),
  lenovoLegionGoLeftStickMove(436),
  lenovoLegionGoLS(437),
  lenovoLegionGoLeftStickDPadNorth(438),
  lenovoLegionGoLeftStickDPadSouth(439),
  lenovoLegionGoLeftStickDPadWest(440),
  lenovoLegionGoLeftStickDPadEast(441),
  lenovoLegionGoRightStickMove(442),
  lenovoLegionGoRS(443),
  lenovoLegionGoRightStickDPadNorth(444),
  lenovoLegionGoRightStickDPadSouth(445),
  lenovoLegionGoRightStickDPadWest(446),
  lenovoLegionGoRightStickDPadEast(447),
  lenovoLegionGoY1(448),
  lenovoLegionGoY2(449),
  lenovoLegionGoDPadMove(450),
  lenovoLegionGoDPadNorth(451),
  lenovoLegionGoDPadSouth(452),
  lenovoLegionGoDPadWest(453),
  lenovoLegionGoDPadEast(454),
  lenovoLegionGoGyroMove(455),
  lenovoLegionGoGyroPitch(456),
  lenovoLegionGoGyroYaw(457),
  lenovoLegionGoGyroRoll(458),
  lenovoLegionGoReserved1(459),
  lenovoLegionGoReserved2(460),
  lenovoLegionGoReserved3(461),
  lenovoLegionGoReserved4(462),
  lenovoLegionGoReserved5(463),
  lenovoLegionGoReserved6(464),
  lenovoLegionGoReserved7(465),
  lenovoLegionGoReserved8(466),
  lenovoLegionGoReserved9(467),
  lenovoLegionGoReserved10(468),
  lenovoLegionGoReserved11(469),
  lenovoLegionGoReserved12(470),
  lenovoLegionGoReserved13(471),
  lenovoLegionGoReserved14(472),
  lenovoLegionGoReserved15(473),
  lenovoLegionGoReserved16(474),
  lenovoLegionGoReserved17(475),
  lenovoLegionGoReserved18(476),
  lenovoLegionGoReserved19(477),
  lenovoLegionGoReserved20(478),
  genericL4(479),
  genericR4(480),
  genericL5(481),
  genericR5(482),
  genericPL(483),
  genericPR(484),
  genericC(485),
  genericZ(486),
  genericMISC1(487),
  genericMISC2(488),
  genericMISC3(489),
  genericMISC4(490),
  genericMISC5(491),
  genericMISC6(492),
  genericMISC7(493),
  genericMISC8(494),
  switch2A(495),
  switch2B(496),
  switch2X(497),
  switch2Y(498),
  switch2LeftBumper(499),
  switch2RightBumper(500),
  switch2Plus(501),
  switch2Minus(502),
  switch2Capture(503),
  switch2LeftTriggerPull(504),
  switch2LeftTriggerClick(505),
  switch2RightTriggerPull(506),
  switch2RightTriggerClick(507),
  switch2LeftStickMove(508),
  switch2LeftStickClick(509),
  switch2LeftStickDPadNorth(510),
  switch2LeftStickDPadSouth(511),
  switch2LeftStickDPadWest(512),
  switch2LeftStickDPadEast(513),
  switch2RightStickMove(514),
  switch2RightStickClick(515),
  switch2RightStickDPadNorth(516),
  switch2RightStickDPadSouth(517),
  switch2RightStickDPadWest(518),
  switch2RightStickDPadEast(519),
  switch2DPadMove(520),
  switch2DPadNorth(521),
  switch2DPadSouth(522),
  switch2DPadWest(523),
  switch2DPadEast(524),
  switch2ProGyroMove(525),
  switch2ProGyroPitch(526),
  switch2ProGyroYaw(527),
  switch2ProGyroRoll(528),
  switch2GL(529),
  switch2GR(530),
  switch2C(531),
  switch2Reserved1(532),
  switch2Reserved2(533),
  switch2Reserved3(534),
  switch2Reserved4(535),
  switch2Reserved5(536),
  switch2Reserved6(537),
  switch2Reserved7(538),
  switch2Reserved8(539),
  switch2Reserved9(540),
  switch2Reserved10(541),
  steamController2026A(542),
  steamController2026B(543),
  steamController2026X(544),
  steamController2026Y(545),
  steamController2026L1(546),
  steamController2026R1(547),
  steamController2026Menu(548),
  steamController2026View(549),
  steamController2026LeftPadTouch(550),
  steamController2026LeftPadSwipe(551),
  steamController2026LeftPadClick(552),
  steamController2026LeftPadDPadNorth(553),
  steamController2026LeftPadDPadSouth(554),
  steamController2026LeftPadDPadWest(555),
  steamController2026LeftPadDPadEast(556),
  steamController2026RightPadTouch(557),
  steamController2026RightPadSwipe(558),
  steamController2026RightPadClick(559),
  steamController2026RightPadDPadNorth(560),
  steamController2026RightPadDPadSouth(561),
  steamController2026RightPadDPadWest(562),
  steamController2026RightPadDPadEast(563),
  steamController2026L2SoftPull(564),
  steamController2026L2(565),
  steamController2026R2SoftPull(566),
  steamController2026R2(567),
  steamController2026LeftStickMove(568),
  steamController2026L3(569),
  steamController2026LeftStickDPadNorth(570),
  steamController2026LeftStickDPadSouth(571),
  steamController2026LeftStickDPadWest(572),
  steamController2026LeftStickDPadEast(573),
  steamController2026LeftStickTouch(574),
  steamController2026RightStickMove(575),
  steamController2026R3(576),
  steamController2026RightStickDPadNorth(577),
  steamController2026RightStickDPadSouth(578),
  steamController2026RightStickDPadWest(579),
  steamController2026RightStickDPadEast(580),
  steamController2026RightStickTouch(581),
  steamController2026L4(582),
  steamController2026R4(583),
  steamController2026L5(584),
  steamController2026R5(585),
  steamController2026DPadMove(586),
  steamController2026DPadNorth(587),
  steamController2026DPadSouth(588),
  steamController2026DPadWest(589),
  steamController2026DPadEast(590),
  steamController2026GyroMove(591),
  steamController2026GyroPitch(592),
  steamController2026GyroYaw(593),
  steamController2026GyroRoll(594),
  steamController2026LGrip(595),
  steamController2026RGrip(596),
  steamController2026Reserved1(597),
  steamController2026Reserved2(598),
  steamController2026Reserved3(599),
  steamController2026Reserved4(600),
  steamController2026Reserved5(601),
  steamController2026Reserved6(602),
  steamController2026Reserved7(603),
  steamController2026Reserved8(604),
  steamController2026Reserved9(605),
  steamController2026Reserved10(606),
  steamController2026Reserved11(607),
  steamController2026Reserved12(608),
  steamController2026Reserved13(609),
  steamController2026Reserved14(610),
  steamController2026Reserved15(611),
  steamController2026Reserved16(612),
  steamController2026Reserved17(613),
  steamController2026Reserved18(614),
  steamController2026Reserved19(615),
  steamController2026Reserved20(616),
  steamFrameControllerAClick(617),
  steamFrameControllerATouch(618),
  steamFrameControllerBClick(619),
  steamFrameControllerBTouch(620),
  steamFrameControllerXClick(621),
  steamFrameControllerXTouch(622),
  steamFrameControllerYClick(623),
  steamFrameControllerYTouch(624),
  steamFrameControllerLeftTriggerPull(625),
  steamFrameControllerLeftTriggerClick(626),
  steamFrameControllerLeftTriggerTouch(627),
  steamFrameControllerRightTriggerPull(628),
  steamFrameControllerRightTriggerClick(629),
  steamFrameControllerRightTriggerTouch(630),
  steamFrameControllerMenuClick(631),
  steamFrameControllerMenuTouch(632),
  steamFrameControllerViewClick(633),
  steamFrameControllerViewTouch(634),
  steamFrameControllerLeftBumperClick(635),
  steamFrameControllerLeftBumperTouch(636),
  steamFrameControllerRightBumperClick(637),
  steamFrameControllerRightBumperTouch(638),
  steamFrameControllerLeftStickMove(639),
  steamFrameControllerLeftStickClick(640),
  steamFrameControllerLeftStickDPadNorth(641),
  steamFrameControllerLeftStickDPadSouth(642),
  steamFrameControllerLeftStickDPadWest(643),
  steamFrameControllerLeftStickDPadEast(644),
  steamFrameControllerLeftStickTouch(645),
  steamFrameControllerRightStickMove(646),
  steamFrameControllerRightStickClick(647),
  steamFrameControllerRightStickDPadNorth(648),
  steamFrameControllerRightStickDPadSouth(649),
  steamFrameControllerRightStickDPadWest(650),
  steamFrameControllerRightStickDPadEast(651),
  steamFrameControllerRightStickTouch(652),
  steamFrameControllerDPadMove(653),
  steamFrameControllerDPadNorth(654),
  steamFrameControllerDPadSouth(655),
  steamFrameControllerDPadWest(656),
  steamFrameControllerDPadEast(657),
  steamFrameControllerDPadTouch(658),
  steamFrameControllerLeftGyroMove(659),
  steamFrameControllerLeftGyroPitch(660),
  steamFrameControllerLeftGyroYaw(661),
  steamFrameControllerLeftGyroRoll(662),
  steamFrameControllerRightGyroMove(663),
  steamFrameControllerRightGyroPitch(664),
  steamFrameControllerRightGyroYaw(665),
  steamFrameControllerRightGyroRoll(666),
  steamFrameControllerLeftGripPull(667),
  steamFrameControllerLeftGripClick(668),
  steamFrameControllerLeftGripTouch(669),
  steamFrameControllerRightGripPull(670),
  steamFrameControllerRightGripClick(671),
  steamFrameControllerRightGripTouch(672),
  steamFrameControllerLeftThumbrestTouch(673),
  steamFrameControllerRightThumbrestTouch(674),
  steamFrameControllerReserved1(675),
  steamFrameControllerReserved2(676),
  steamFrameControllerReserved3(677),
  steamFrameControllerReserved4(678),
  steamFrameControllerReserved5(679),
  steamFrameControllerReserved6(680),
  steamFrameControllerReserved7(681),
  steamFrameControllerReserved8(682),
  steamFrameControllerReserved9(683),
  steamFrameControllerReserved10(684),
  steamFrameControllerReserved11(685),
  steamFrameControllerReserved12(686),
  steamFrameControllerReserved13(687),
  steamFrameControllerReserved14(688),
  steamFrameControllerReserved15(689),
  steamFrameControllerReserved16(690),
  steamFrameControllerReserved17(691),
  steamFrameControllerReserved18(692),
  steamFrameControllerReserved19(693),
  steamFrameControllerReserved20(694),
  count(695),
  maximumPossibleValue(32767),
  ;

  final int value;

  const EInputActionOrigin(this.value);

  factory EInputActionOrigin.fromValue(int value) {
    switch (value) {
      case 0:
        return EInputActionOrigin.none;
      case 1:
        return EInputActionOrigin.steamControllerA;
      case 2:
        return EInputActionOrigin.steamControllerB;
      case 3:
        return EInputActionOrigin.steamControllerX;
      case 4:
        return EInputActionOrigin.steamControllerY;
      case 5:
        return EInputActionOrigin.steamControllerLeftBumper;
      case 6:
        return EInputActionOrigin.steamControllerRightBumper;
      case 7:
        return EInputActionOrigin.steamControllerLeftGrip;
      case 8:
        return EInputActionOrigin.steamControllerRightGrip;
      case 9:
        return EInputActionOrigin.steamControllerStart;
      case 10:
        return EInputActionOrigin.steamControllerBack;
      case 11:
        return EInputActionOrigin.steamControllerLeftPadTouch;
      case 12:
        return EInputActionOrigin.steamControllerLeftPadSwipe;
      case 13:
        return EInputActionOrigin.steamControllerLeftPadClick;
      case 14:
        return EInputActionOrigin.steamControllerLeftPadDPadNorth;
      case 15:
        return EInputActionOrigin.steamControllerLeftPadDPadSouth;
      case 16:
        return EInputActionOrigin.steamControllerLeftPadDPadWest;
      case 17:
        return EInputActionOrigin.steamControllerLeftPadDPadEast;
      case 18:
        return EInputActionOrigin.steamControllerRightPadTouch;
      case 19:
        return EInputActionOrigin.steamControllerRightPadSwipe;
      case 20:
        return EInputActionOrigin.steamControllerRightPadClick;
      case 21:
        return EInputActionOrigin.steamControllerRightPadDPadNorth;
      case 22:
        return EInputActionOrigin.steamControllerRightPadDPadSouth;
      case 23:
        return EInputActionOrigin.steamControllerRightPadDPadWest;
      case 24:
        return EInputActionOrigin.steamControllerRightPadDPadEast;
      case 25:
        return EInputActionOrigin.steamControllerLeftTriggerPull;
      case 26:
        return EInputActionOrigin.steamControllerLeftTriggerClick;
      case 27:
        return EInputActionOrigin.steamControllerRightTriggerPull;
      case 28:
        return EInputActionOrigin.steamControllerRightTriggerClick;
      case 29:
        return EInputActionOrigin.steamControllerLeftStickMove;
      case 30:
        return EInputActionOrigin.steamControllerLeftStickClick;
      case 31:
        return EInputActionOrigin.steamControllerLeftStickDPadNorth;
      case 32:
        return EInputActionOrigin.steamControllerLeftStickDPadSouth;
      case 33:
        return EInputActionOrigin.steamControllerLeftStickDPadWest;
      case 34:
        return EInputActionOrigin.steamControllerLeftStickDPadEast;
      case 35:
        return EInputActionOrigin.steamControllerGyroMove;
      case 36:
        return EInputActionOrigin.steamControllerGyroPitch;
      case 37:
        return EInputActionOrigin.steamControllerGyroYaw;
      case 38:
        return EInputActionOrigin.steamControllerGyroRoll;
      case 39:
        return EInputActionOrigin.steamControllerReserved0;
      case 40:
        return EInputActionOrigin.steamControllerReserved1;
      case 41:
        return EInputActionOrigin.steamControllerReserved2;
      case 42:
        return EInputActionOrigin.steamControllerReserved3;
      case 43:
        return EInputActionOrigin.steamControllerReserved4;
      case 44:
        return EInputActionOrigin.steamControllerReserved5;
      case 45:
        return EInputActionOrigin.steamControllerReserved6;
      case 46:
        return EInputActionOrigin.steamControllerReserved7;
      case 47:
        return EInputActionOrigin.steamControllerReserved8;
      case 48:
        return EInputActionOrigin.steamControllerReserved9;
      case 49:
        return EInputActionOrigin.steamControllerReserved10;
      case 50:
        return EInputActionOrigin.ps4X;
      case 51:
        return EInputActionOrigin.ps4Circle;
      case 52:
        return EInputActionOrigin.ps4Triangle;
      case 53:
        return EInputActionOrigin.ps4Square;
      case 54:
        return EInputActionOrigin.ps4LeftBumper;
      case 55:
        return EInputActionOrigin.ps4RightBumper;
      case 56:
        return EInputActionOrigin.ps4Options;
      case 57:
        return EInputActionOrigin.ps4Share;
      case 58:
        return EInputActionOrigin.ps4LeftPadTouch;
      case 59:
        return EInputActionOrigin.ps4LeftPadSwipe;
      case 60:
        return EInputActionOrigin.ps4LeftPadClick;
      case 61:
        return EInputActionOrigin.ps4LeftPadDPadNorth;
      case 62:
        return EInputActionOrigin.ps4LeftPadDPadSouth;
      case 63:
        return EInputActionOrigin.ps4LeftPadDPadWest;
      case 64:
        return EInputActionOrigin.ps4LeftPadDPadEast;
      case 65:
        return EInputActionOrigin.ps4RightPadTouch;
      case 66:
        return EInputActionOrigin.ps4RightPadSwipe;
      case 67:
        return EInputActionOrigin.ps4RightPadClick;
      case 68:
        return EInputActionOrigin.ps4RightPadDPadNorth;
      case 69:
        return EInputActionOrigin.ps4RightPadDPadSouth;
      case 70:
        return EInputActionOrigin.ps4RightPadDPadWest;
      case 71:
        return EInputActionOrigin.ps4RightPadDPadEast;
      case 72:
        return EInputActionOrigin.ps4CenterPadTouch;
      case 73:
        return EInputActionOrigin.ps4CenterPadSwipe;
      case 74:
        return EInputActionOrigin.ps4CenterPadClick;
      case 75:
        return EInputActionOrigin.ps4CenterPadDPadNorth;
      case 76:
        return EInputActionOrigin.ps4CenterPadDPadSouth;
      case 77:
        return EInputActionOrigin.ps4CenterPadDPadWest;
      case 78:
        return EInputActionOrigin.ps4CenterPadDPadEast;
      case 79:
        return EInputActionOrigin.ps4LeftTriggerPull;
      case 80:
        return EInputActionOrigin.ps4LeftTriggerClick;
      case 81:
        return EInputActionOrigin.ps4RightTriggerPull;
      case 82:
        return EInputActionOrigin.ps4RightTriggerClick;
      case 83:
        return EInputActionOrigin.ps4LeftStickMove;
      case 84:
        return EInputActionOrigin.ps4LeftStickClick;
      case 85:
        return EInputActionOrigin.ps4LeftStickDPadNorth;
      case 86:
        return EInputActionOrigin.ps4LeftStickDPadSouth;
      case 87:
        return EInputActionOrigin.ps4LeftStickDPadWest;
      case 88:
        return EInputActionOrigin.ps4LeftStickDPadEast;
      case 89:
        return EInputActionOrigin.ps4RightStickMove;
      case 90:
        return EInputActionOrigin.ps4RightStickClick;
      case 91:
        return EInputActionOrigin.ps4RightStickDPadNorth;
      case 92:
        return EInputActionOrigin.ps4RightStickDPadSouth;
      case 93:
        return EInputActionOrigin.ps4RightStickDPadWest;
      case 94:
        return EInputActionOrigin.ps4RightStickDPadEast;
      case 95:
        return EInputActionOrigin.ps4DPadNorth;
      case 96:
        return EInputActionOrigin.ps4DPadSouth;
      case 97:
        return EInputActionOrigin.ps4DPadWest;
      case 98:
        return EInputActionOrigin.ps4DPadEast;
      case 99:
        return EInputActionOrigin.ps4GyroMove;
      case 100:
        return EInputActionOrigin.ps4GyroPitch;
      case 101:
        return EInputActionOrigin.ps4GyroYaw;
      case 102:
        return EInputActionOrigin.ps4GyroRoll;
      case 103:
        return EInputActionOrigin.ps4DPadMove;
      case 104:
        return EInputActionOrigin.ps4Reserved1;
      case 105:
        return EInputActionOrigin.ps4Reserved2;
      case 106:
        return EInputActionOrigin.ps4Reserved3;
      case 107:
        return EInputActionOrigin.ps4Reserved4;
      case 108:
        return EInputActionOrigin.ps4Reserved5;
      case 109:
        return EInputActionOrigin.ps4Reserved6;
      case 110:
        return EInputActionOrigin.ps4Reserved7;
      case 111:
        return EInputActionOrigin.ps4Reserved8;
      case 112:
        return EInputActionOrigin.ps4Reserved9;
      case 113:
        return EInputActionOrigin.ps4Reserved10;
      case 114:
        return EInputActionOrigin.xBoxOneA;
      case 115:
        return EInputActionOrigin.xBoxOneB;
      case 116:
        return EInputActionOrigin.xBoxOneX;
      case 117:
        return EInputActionOrigin.xBoxOneY;
      case 118:
        return EInputActionOrigin.xBoxOneLeftBumper;
      case 119:
        return EInputActionOrigin.xBoxOneRightBumper;
      case 120:
        return EInputActionOrigin.xBoxOneMenu;
      case 121:
        return EInputActionOrigin.xBoxOneView;
      case 122:
        return EInputActionOrigin.xBoxOneLeftTriggerPull;
      case 123:
        return EInputActionOrigin.xBoxOneLeftTriggerClick;
      case 124:
        return EInputActionOrigin.xBoxOneRightTriggerPull;
      case 125:
        return EInputActionOrigin.xBoxOneRightTriggerClick;
      case 126:
        return EInputActionOrigin.xBoxOneLeftStickMove;
      case 127:
        return EInputActionOrigin.xBoxOneLeftStickClick;
      case 128:
        return EInputActionOrigin.xBoxOneLeftStickDPadNorth;
      case 129:
        return EInputActionOrigin.xBoxOneLeftStickDPadSouth;
      case 130:
        return EInputActionOrigin.xBoxOneLeftStickDPadWest;
      case 131:
        return EInputActionOrigin.xBoxOneLeftStickDPadEast;
      case 132:
        return EInputActionOrigin.xBoxOneRightStickMove;
      case 133:
        return EInputActionOrigin.xBoxOneRightStickClick;
      case 134:
        return EInputActionOrigin.xBoxOneRightStickDPadNorth;
      case 135:
        return EInputActionOrigin.xBoxOneRightStickDPadSouth;
      case 136:
        return EInputActionOrigin.xBoxOneRightStickDPadWest;
      case 137:
        return EInputActionOrigin.xBoxOneRightStickDPadEast;
      case 138:
        return EInputActionOrigin.xBoxOneDPadNorth;
      case 139:
        return EInputActionOrigin.xBoxOneDPadSouth;
      case 140:
        return EInputActionOrigin.xBoxOneDPadWest;
      case 141:
        return EInputActionOrigin.xBoxOneDPadEast;
      case 142:
        return EInputActionOrigin.xBoxOneDPadMove;
      case 143:
        return EInputActionOrigin.xBoxOneLeftGripLower;
      case 144:
        return EInputActionOrigin.xBoxOneLeftGripUpper;
      case 145:
        return EInputActionOrigin.xBoxOneRightGripLower;
      case 146:
        return EInputActionOrigin.xBoxOneRightGripUpper;
      case 147:
        return EInputActionOrigin.xBoxOneShare;
      case 148:
        return EInputActionOrigin.xBoxOneReserved6;
      case 149:
        return EInputActionOrigin.xBoxOneReserved7;
      case 150:
        return EInputActionOrigin.xBoxOneReserved8;
      case 151:
        return EInputActionOrigin.xBoxOneReserved9;
      case 152:
        return EInputActionOrigin.xBoxOneReserved10;
      case 153:
        return EInputActionOrigin.xBox360A;
      case 154:
        return EInputActionOrigin.xBox360B;
      case 155:
        return EInputActionOrigin.xBox360X;
      case 156:
        return EInputActionOrigin.xBox360Y;
      case 157:
        return EInputActionOrigin.xBox360LeftBumper;
      case 158:
        return EInputActionOrigin.xBox360RightBumper;
      case 159:
        return EInputActionOrigin.xBox360Start;
      case 160:
        return EInputActionOrigin.xBox360Back;
      case 161:
        return EInputActionOrigin.xBox360LeftTriggerPull;
      case 162:
        return EInputActionOrigin.xBox360LeftTriggerClick;
      case 163:
        return EInputActionOrigin.xBox360RightTriggerPull;
      case 164:
        return EInputActionOrigin.xBox360RightTriggerClick;
      case 165:
        return EInputActionOrigin.xBox360LeftStickMove;
      case 166:
        return EInputActionOrigin.xBox360LeftStickClick;
      case 167:
        return EInputActionOrigin.xBox360LeftStickDPadNorth;
      case 168:
        return EInputActionOrigin.xBox360LeftStickDPadSouth;
      case 169:
        return EInputActionOrigin.xBox360LeftStickDPadWest;
      case 170:
        return EInputActionOrigin.xBox360LeftStickDPadEast;
      case 171:
        return EInputActionOrigin.xBox360RightStickMove;
      case 172:
        return EInputActionOrigin.xBox360RightStickClick;
      case 173:
        return EInputActionOrigin.xBox360RightStickDPadNorth;
      case 174:
        return EInputActionOrigin.xBox360RightStickDPadSouth;
      case 175:
        return EInputActionOrigin.xBox360RightStickDPadWest;
      case 176:
        return EInputActionOrigin.xBox360RightStickDPadEast;
      case 177:
        return EInputActionOrigin.xBox360DPadNorth;
      case 178:
        return EInputActionOrigin.xBox360DPadSouth;
      case 179:
        return EInputActionOrigin.xBox360DPadWest;
      case 180:
        return EInputActionOrigin.xBox360DPadEast;
      case 181:
        return EInputActionOrigin.xBox360DPadMove;
      case 182:
        return EInputActionOrigin.xBox360Reserved1;
      case 183:
        return EInputActionOrigin.xBox360Reserved2;
      case 184:
        return EInputActionOrigin.xBox360Reserved3;
      case 185:
        return EInputActionOrigin.xBox360Reserved4;
      case 186:
        return EInputActionOrigin.xBox360Reserved5;
      case 187:
        return EInputActionOrigin.xBox360Reserved6;
      case 188:
        return EInputActionOrigin.xBox360Reserved7;
      case 189:
        return EInputActionOrigin.xBox360Reserved8;
      case 190:
        return EInputActionOrigin.xBox360Reserved9;
      case 191:
        return EInputActionOrigin.xBox360Reserved10;
      case 192:
        return EInputActionOrigin.switchA;
      case 193:
        return EInputActionOrigin.switchB;
      case 194:
        return EInputActionOrigin.switchX;
      case 195:
        return EInputActionOrigin.switchY;
      case 196:
        return EInputActionOrigin.switchLeftBumper;
      case 197:
        return EInputActionOrigin.switchRightBumper;
      case 198:
        return EInputActionOrigin.switchPlus;
      case 199:
        return EInputActionOrigin.switchMinus;
      case 200:
        return EInputActionOrigin.switchCapture;
      case 201:
        return EInputActionOrigin.switchLeftTriggerPull;
      case 202:
        return EInputActionOrigin.switchLeftTriggerClick;
      case 203:
        return EInputActionOrigin.switchRightTriggerPull;
      case 204:
        return EInputActionOrigin.switchRightTriggerClick;
      case 205:
        return EInputActionOrigin.switchLeftStickMove;
      case 206:
        return EInputActionOrigin.switchLeftStickClick;
      case 207:
        return EInputActionOrigin.switchLeftStickDPadNorth;
      case 208:
        return EInputActionOrigin.switchLeftStickDPadSouth;
      case 209:
        return EInputActionOrigin.switchLeftStickDPadWest;
      case 210:
        return EInputActionOrigin.switchLeftStickDPadEast;
      case 211:
        return EInputActionOrigin.switchRightStickMove;
      case 212:
        return EInputActionOrigin.switchRightStickClick;
      case 213:
        return EInputActionOrigin.switchRightStickDPadNorth;
      case 214:
        return EInputActionOrigin.switchRightStickDPadSouth;
      case 215:
        return EInputActionOrigin.switchRightStickDPadWest;
      case 216:
        return EInputActionOrigin.switchRightStickDPadEast;
      case 217:
        return EInputActionOrigin.switchDPadNorth;
      case 218:
        return EInputActionOrigin.switchDPadSouth;
      case 219:
        return EInputActionOrigin.switchDPadWest;
      case 220:
        return EInputActionOrigin.switchDPadEast;
      case 221:
        return EInputActionOrigin.switchProGyroMove;
      case 222:
        return EInputActionOrigin.switchProGyroPitch;
      case 223:
        return EInputActionOrigin.switchProGyroYaw;
      case 224:
        return EInputActionOrigin.switchProGyroRoll;
      case 225:
        return EInputActionOrigin.switchDPadMove;
      case 226:
        return EInputActionOrigin.switchReserved1;
      case 227:
        return EInputActionOrigin.switchReserved2;
      case 228:
        return EInputActionOrigin.switchReserved3;
      case 229:
        return EInputActionOrigin.switchReserved4;
      case 230:
        return EInputActionOrigin.switchReserved5;
      case 231:
        return EInputActionOrigin.switchReserved6;
      case 232:
        return EInputActionOrigin.switchReserved7;
      case 233:
        return EInputActionOrigin.switchReserved8;
      case 234:
        return EInputActionOrigin.switchReserved9;
      case 235:
        return EInputActionOrigin.switchReserved10;
      case 236:
        return EInputActionOrigin.switchRightGyroMove;
      case 237:
        return EInputActionOrigin.switchRightGyroPitch;
      case 238:
        return EInputActionOrigin.switchRightGyroYaw;
      case 239:
        return EInputActionOrigin.switchRightGyroRoll;
      case 240:
        return EInputActionOrigin.switchLeftGyroMove;
      case 241:
        return EInputActionOrigin.switchLeftGyroPitch;
      case 242:
        return EInputActionOrigin.switchLeftGyroYaw;
      case 243:
        return EInputActionOrigin.switchLeftGyroRoll;
      case 244:
        return EInputActionOrigin.switchLeftGripLower;
      case 245:
        return EInputActionOrigin.switchLeftGripUpper;
      case 246:
        return EInputActionOrigin.switchRightGripLower;
      case 247:
        return EInputActionOrigin.switchRightGripUpper;
      case 248:
        return EInputActionOrigin.switchJoyConButtonN;
      case 249:
        return EInputActionOrigin.switchJoyConButtonE;
      case 250:
        return EInputActionOrigin.switchJoyConButtonS;
      case 251:
        return EInputActionOrigin.switchJoyConButtonW;
      case 252:
        return EInputActionOrigin.switchReserved15;
      case 253:
        return EInputActionOrigin.switchReserved16;
      case 254:
        return EInputActionOrigin.switchReserved17;
      case 255:
        return EInputActionOrigin.switchReserved18;
      case 256:
        return EInputActionOrigin.switchReserved19;
      case 257:
        return EInputActionOrigin.switchReserved20;
      case 258:
        return EInputActionOrigin.ps5X;
      case 259:
        return EInputActionOrigin.ps5Circle;
      case 260:
        return EInputActionOrigin.ps5Triangle;
      case 261:
        return EInputActionOrigin.ps5Square;
      case 262:
        return EInputActionOrigin.ps5LeftBumper;
      case 263:
        return EInputActionOrigin.ps5RightBumper;
      case 264:
        return EInputActionOrigin.ps5Option;
      case 265:
        return EInputActionOrigin.ps5Create;
      case 266:
        return EInputActionOrigin.ps5Mute;
      case 267:
        return EInputActionOrigin.ps5LeftPadTouch;
      case 268:
        return EInputActionOrigin.ps5LeftPadSwipe;
      case 269:
        return EInputActionOrigin.ps5LeftPadClick;
      case 270:
        return EInputActionOrigin.ps5LeftPadDPadNorth;
      case 271:
        return EInputActionOrigin.ps5LeftPadDPadSouth;
      case 272:
        return EInputActionOrigin.ps5LeftPadDPadWest;
      case 273:
        return EInputActionOrigin.ps5LeftPadDPadEast;
      case 274:
        return EInputActionOrigin.ps5RightPadTouch;
      case 275:
        return EInputActionOrigin.ps5RightPadSwipe;
      case 276:
        return EInputActionOrigin.ps5RightPadClick;
      case 277:
        return EInputActionOrigin.ps5RightPadDPadNorth;
      case 278:
        return EInputActionOrigin.ps5RightPadDPadSouth;
      case 279:
        return EInputActionOrigin.ps5RightPadDPadWest;
      case 280:
        return EInputActionOrigin.ps5RightPadDPadEast;
      case 281:
        return EInputActionOrigin.ps5CenterPadTouch;
      case 282:
        return EInputActionOrigin.ps5CenterPadSwipe;
      case 283:
        return EInputActionOrigin.ps5CenterPadClick;
      case 284:
        return EInputActionOrigin.ps5CenterPadDPadNorth;
      case 285:
        return EInputActionOrigin.ps5CenterPadDPadSouth;
      case 286:
        return EInputActionOrigin.ps5CenterPadDPadWest;
      case 287:
        return EInputActionOrigin.ps5CenterPadDPadEast;
      case 288:
        return EInputActionOrigin.ps5LeftTriggerPull;
      case 289:
        return EInputActionOrigin.ps5LeftTriggerClick;
      case 290:
        return EInputActionOrigin.ps5RightTriggerPull;
      case 291:
        return EInputActionOrigin.ps5RightTriggerClick;
      case 292:
        return EInputActionOrigin.ps5LeftStickMove;
      case 293:
        return EInputActionOrigin.ps5LeftStickClick;
      case 294:
        return EInputActionOrigin.ps5LeftStickDPadNorth;
      case 295:
        return EInputActionOrigin.ps5LeftStickDPadSouth;
      case 296:
        return EInputActionOrigin.ps5LeftStickDPadWest;
      case 297:
        return EInputActionOrigin.ps5LeftStickDPadEast;
      case 298:
        return EInputActionOrigin.ps5RightStickMove;
      case 299:
        return EInputActionOrigin.ps5RightStickClick;
      case 300:
        return EInputActionOrigin.ps5RightStickDPadNorth;
      case 301:
        return EInputActionOrigin.ps5RightStickDPadSouth;
      case 302:
        return EInputActionOrigin.ps5RightStickDPadWest;
      case 303:
        return EInputActionOrigin.ps5RightStickDPadEast;
      case 304:
        return EInputActionOrigin.ps5DPadNorth;
      case 305:
        return EInputActionOrigin.ps5DPadSouth;
      case 306:
        return EInputActionOrigin.ps5DPadWest;
      case 307:
        return EInputActionOrigin.ps5DPadEast;
      case 308:
        return EInputActionOrigin.ps5GyroMove;
      case 309:
        return EInputActionOrigin.ps5GyroPitch;
      case 310:
        return EInputActionOrigin.ps5GyroYaw;
      case 311:
        return EInputActionOrigin.ps5GyroRoll;
      case 312:
        return EInputActionOrigin.ps5DPadMove;
      case 313:
        return EInputActionOrigin.ps5LeftGrip;
      case 314:
        return EInputActionOrigin.ps5RightGrip;
      case 315:
        return EInputActionOrigin.ps5LeftFn;
      case 316:
        return EInputActionOrigin.ps5RightFn;
      case 317:
        return EInputActionOrigin.ps5Reserved5;
      case 318:
        return EInputActionOrigin.ps5Reserved6;
      case 319:
        return EInputActionOrigin.ps5Reserved7;
      case 320:
        return EInputActionOrigin.ps5Reserved8;
      case 321:
        return EInputActionOrigin.ps5Reserved9;
      case 322:
        return EInputActionOrigin.ps5Reserved10;
      case 323:
        return EInputActionOrigin.ps5Reserved11;
      case 324:
        return EInputActionOrigin.ps5Reserved12;
      case 325:
        return EInputActionOrigin.ps5Reserved13;
      case 326:
        return EInputActionOrigin.ps5Reserved14;
      case 327:
        return EInputActionOrigin.ps5Reserved15;
      case 328:
        return EInputActionOrigin.ps5Reserved16;
      case 329:
        return EInputActionOrigin.ps5Reserved17;
      case 330:
        return EInputActionOrigin.ps5Reserved18;
      case 331:
        return EInputActionOrigin.ps5Reserved19;
      case 332:
        return EInputActionOrigin.ps5Reserved20;
      case 333:
        return EInputActionOrigin.steamDeckA;
      case 334:
        return EInputActionOrigin.steamDeckB;
      case 335:
        return EInputActionOrigin.steamDeckX;
      case 336:
        return EInputActionOrigin.steamDeckY;
      case 337:
        return EInputActionOrigin.steamDeckL1;
      case 338:
        return EInputActionOrigin.steamDeckR1;
      case 339:
        return EInputActionOrigin.steamDeckMenu;
      case 340:
        return EInputActionOrigin.steamDeckView;
      case 341:
        return EInputActionOrigin.steamDeckLeftPadTouch;
      case 342:
        return EInputActionOrigin.steamDeckLeftPadSwipe;
      case 343:
        return EInputActionOrigin.steamDeckLeftPadClick;
      case 344:
        return EInputActionOrigin.steamDeckLeftPadDPadNorth;
      case 345:
        return EInputActionOrigin.steamDeckLeftPadDPadSouth;
      case 346:
        return EInputActionOrigin.steamDeckLeftPadDPadWest;
      case 347:
        return EInputActionOrigin.steamDeckLeftPadDPadEast;
      case 348:
        return EInputActionOrigin.steamDeckRightPadTouch;
      case 349:
        return EInputActionOrigin.steamDeckRightPadSwipe;
      case 350:
        return EInputActionOrigin.steamDeckRightPadClick;
      case 351:
        return EInputActionOrigin.steamDeckRightPadDPadNorth;
      case 352:
        return EInputActionOrigin.steamDeckRightPadDPadSouth;
      case 353:
        return EInputActionOrigin.steamDeckRightPadDPadWest;
      case 354:
        return EInputActionOrigin.steamDeckRightPadDPadEast;
      case 355:
        return EInputActionOrigin.steamDeckL2SoftPull;
      case 356:
        return EInputActionOrigin.steamDeckL2;
      case 357:
        return EInputActionOrigin.steamDeckR2SoftPull;
      case 358:
        return EInputActionOrigin.steamDeckR2;
      case 359:
        return EInputActionOrigin.steamDeckLeftStickMove;
      case 360:
        return EInputActionOrigin.steamDeckL3;
      case 361:
        return EInputActionOrigin.steamDeckLeftStickDPadNorth;
      case 362:
        return EInputActionOrigin.steamDeckLeftStickDPadSouth;
      case 363:
        return EInputActionOrigin.steamDeckLeftStickDPadWest;
      case 364:
        return EInputActionOrigin.steamDeckLeftStickDPadEast;
      case 365:
        return EInputActionOrigin.steamDeckLeftStickTouch;
      case 366:
        return EInputActionOrigin.steamDeckRightStickMove;
      case 367:
        return EInputActionOrigin.steamDeckR3;
      case 368:
        return EInputActionOrigin.steamDeckRightStickDPadNorth;
      case 369:
        return EInputActionOrigin.steamDeckRightStickDPadSouth;
      case 370:
        return EInputActionOrigin.steamDeckRightStickDPadWest;
      case 371:
        return EInputActionOrigin.steamDeckRightStickDPadEast;
      case 372:
        return EInputActionOrigin.steamDeckRightStickTouch;
      case 373:
        return EInputActionOrigin.steamDeckL4;
      case 374:
        return EInputActionOrigin.steamDeckR4;
      case 375:
        return EInputActionOrigin.steamDeckL5;
      case 376:
        return EInputActionOrigin.steamDeckR5;
      case 377:
        return EInputActionOrigin.steamDeckDPadMove;
      case 378:
        return EInputActionOrigin.steamDeckDPadNorth;
      case 379:
        return EInputActionOrigin.steamDeckDPadSouth;
      case 380:
        return EInputActionOrigin.steamDeckDPadWest;
      case 381:
        return EInputActionOrigin.steamDeckDPadEast;
      case 382:
        return EInputActionOrigin.steamDeckGyroMove;
      case 383:
        return EInputActionOrigin.steamDeckGyroPitch;
      case 384:
        return EInputActionOrigin.steamDeckGyroYaw;
      case 385:
        return EInputActionOrigin.steamDeckGyroRoll;
      case 386:
        return EInputActionOrigin.steamDeckReserved1;
      case 387:
        return EInputActionOrigin.steamDeckReserved2;
      case 388:
        return EInputActionOrigin.steamDeckReserved3;
      case 389:
        return EInputActionOrigin.steamDeckReserved4;
      case 390:
        return EInputActionOrigin.steamDeckReserved5;
      case 391:
        return EInputActionOrigin.steamDeckReserved6;
      case 392:
        return EInputActionOrigin.steamDeckReserved7;
      case 393:
        return EInputActionOrigin.steamDeckReserved8;
      case 394:
        return EInputActionOrigin.steamDeckReserved9;
      case 395:
        return EInputActionOrigin.steamDeckReserved10;
      case 396:
        return EInputActionOrigin.steamDeckReserved11;
      case 397:
        return EInputActionOrigin.steamDeckReserved12;
      case 398:
        return EInputActionOrigin.steamDeckReserved13;
      case 399:
        return EInputActionOrigin.steamDeckReserved14;
      case 400:
        return EInputActionOrigin.steamDeckReserved15;
      case 401:
        return EInputActionOrigin.steamDeckReserved16;
      case 402:
        return EInputActionOrigin.steamDeckReserved17;
      case 403:
        return EInputActionOrigin.steamDeckReserved18;
      case 404:
        return EInputActionOrigin.steamDeckReserved19;
      case 405:
        return EInputActionOrigin.steamDeckReserved20;
      case 406:
        return EInputActionOrigin.horipadM1;
      case 407:
        return EInputActionOrigin.horipadM2;
      case 408:
        return EInputActionOrigin.horipadL4;
      case 409:
        return EInputActionOrigin.horipadR4;
      case 410:
        return EInputActionOrigin.lenovoLegionGoA;
      case 411:
        return EInputActionOrigin.lenovoLegionGoB;
      case 412:
        return EInputActionOrigin.lenovoLegionGoX;
      case 413:
        return EInputActionOrigin.lenovoLegionGoY;
      case 414:
        return EInputActionOrigin.lenovoLegionGoLB;
      case 415:
        return EInputActionOrigin.lenovoLegionGoRB;
      case 416:
        return EInputActionOrigin.lenovoLegionGoMenu;
      case 417:
        return EInputActionOrigin.lenovoLegionGoView;
      case 418:
        return EInputActionOrigin.lenovoLegionGoLeftPadTouch;
      case 419:
        return EInputActionOrigin.lenovoLegionGoLeftPadSwipe;
      case 420:
        return EInputActionOrigin.lenovoLegionGoLeftPadClick;
      case 421:
        return EInputActionOrigin.lenovoLegionGoLeftPadDPadNorth;
      case 422:
        return EInputActionOrigin.lenovoLegionGoLeftPadDPadSouth;
      case 423:
        return EInputActionOrigin.lenovoLegionGoLeftPadDPadWest;
      case 424:
        return EInputActionOrigin.lenovoLegionGoLeftPadDPadEast;
      case 425:
        return EInputActionOrigin.lenovoLegionGoRightPadTouch;
      case 426:
        return EInputActionOrigin.lenovoLegionGoRightPadSwipe;
      case 427:
        return EInputActionOrigin.lenovoLegionGoRightPadClick;
      case 428:
        return EInputActionOrigin.lenovoLegionGoRightPadDPadNorth;
      case 429:
        return EInputActionOrigin.lenovoLegionGoRightPadDPadSouth;
      case 430:
        return EInputActionOrigin.lenovoLegionGoRightPadDPadWest;
      case 431:
        return EInputActionOrigin.lenovoLegionGoRightPadDPadEast;
      case 432:
        return EInputActionOrigin.lenovoLegionGoLTSoftPull;
      case 433:
        return EInputActionOrigin.lenovoLegionGoLT;
      case 434:
        return EInputActionOrigin.lenovoLegionGoRTSoftPull;
      case 435:
        return EInputActionOrigin.lenovoLegionGoRT;
      case 436:
        return EInputActionOrigin.lenovoLegionGoLeftStickMove;
      case 437:
        return EInputActionOrigin.lenovoLegionGoLS;
      case 438:
        return EInputActionOrigin.lenovoLegionGoLeftStickDPadNorth;
      case 439:
        return EInputActionOrigin.lenovoLegionGoLeftStickDPadSouth;
      case 440:
        return EInputActionOrigin.lenovoLegionGoLeftStickDPadWest;
      case 441:
        return EInputActionOrigin.lenovoLegionGoLeftStickDPadEast;
      case 442:
        return EInputActionOrigin.lenovoLegionGoRightStickMove;
      case 443:
        return EInputActionOrigin.lenovoLegionGoRS;
      case 444:
        return EInputActionOrigin.lenovoLegionGoRightStickDPadNorth;
      case 445:
        return EInputActionOrigin.lenovoLegionGoRightStickDPadSouth;
      case 446:
        return EInputActionOrigin.lenovoLegionGoRightStickDPadWest;
      case 447:
        return EInputActionOrigin.lenovoLegionGoRightStickDPadEast;
      case 448:
        return EInputActionOrigin.lenovoLegionGoY1;
      case 449:
        return EInputActionOrigin.lenovoLegionGoY2;
      case 450:
        return EInputActionOrigin.lenovoLegionGoDPadMove;
      case 451:
        return EInputActionOrigin.lenovoLegionGoDPadNorth;
      case 452:
        return EInputActionOrigin.lenovoLegionGoDPadSouth;
      case 453:
        return EInputActionOrigin.lenovoLegionGoDPadWest;
      case 454:
        return EInputActionOrigin.lenovoLegionGoDPadEast;
      case 455:
        return EInputActionOrigin.lenovoLegionGoGyroMove;
      case 456:
        return EInputActionOrigin.lenovoLegionGoGyroPitch;
      case 457:
        return EInputActionOrigin.lenovoLegionGoGyroYaw;
      case 458:
        return EInputActionOrigin.lenovoLegionGoGyroRoll;
      case 459:
        return EInputActionOrigin.lenovoLegionGoReserved1;
      case 460:
        return EInputActionOrigin.lenovoLegionGoReserved2;
      case 461:
        return EInputActionOrigin.lenovoLegionGoReserved3;
      case 462:
        return EInputActionOrigin.lenovoLegionGoReserved4;
      case 463:
        return EInputActionOrigin.lenovoLegionGoReserved5;
      case 464:
        return EInputActionOrigin.lenovoLegionGoReserved6;
      case 465:
        return EInputActionOrigin.lenovoLegionGoReserved7;
      case 466:
        return EInputActionOrigin.lenovoLegionGoReserved8;
      case 467:
        return EInputActionOrigin.lenovoLegionGoReserved9;
      case 468:
        return EInputActionOrigin.lenovoLegionGoReserved10;
      case 469:
        return EInputActionOrigin.lenovoLegionGoReserved11;
      case 470:
        return EInputActionOrigin.lenovoLegionGoReserved12;
      case 471:
        return EInputActionOrigin.lenovoLegionGoReserved13;
      case 472:
        return EInputActionOrigin.lenovoLegionGoReserved14;
      case 473:
        return EInputActionOrigin.lenovoLegionGoReserved15;
      case 474:
        return EInputActionOrigin.lenovoLegionGoReserved16;
      case 475:
        return EInputActionOrigin.lenovoLegionGoReserved17;
      case 476:
        return EInputActionOrigin.lenovoLegionGoReserved18;
      case 477:
        return EInputActionOrigin.lenovoLegionGoReserved19;
      case 478:
        return EInputActionOrigin.lenovoLegionGoReserved20;
      case 479:
        return EInputActionOrigin.genericL4;
      case 480:
        return EInputActionOrigin.genericR4;
      case 481:
        return EInputActionOrigin.genericL5;
      case 482:
        return EInputActionOrigin.genericR5;
      case 483:
        return EInputActionOrigin.genericPL;
      case 484:
        return EInputActionOrigin.genericPR;
      case 485:
        return EInputActionOrigin.genericC;
      case 486:
        return EInputActionOrigin.genericZ;
      case 487:
        return EInputActionOrigin.genericMISC1;
      case 488:
        return EInputActionOrigin.genericMISC2;
      case 489:
        return EInputActionOrigin.genericMISC3;
      case 490:
        return EInputActionOrigin.genericMISC4;
      case 491:
        return EInputActionOrigin.genericMISC5;
      case 492:
        return EInputActionOrigin.genericMISC6;
      case 493:
        return EInputActionOrigin.genericMISC7;
      case 494:
        return EInputActionOrigin.genericMISC8;
      case 495:
        return EInputActionOrigin.switch2A;
      case 496:
        return EInputActionOrigin.switch2B;
      case 497:
        return EInputActionOrigin.switch2X;
      case 498:
        return EInputActionOrigin.switch2Y;
      case 499:
        return EInputActionOrigin.switch2LeftBumper;
      case 500:
        return EInputActionOrigin.switch2RightBumper;
      case 501:
        return EInputActionOrigin.switch2Plus;
      case 502:
        return EInputActionOrigin.switch2Minus;
      case 503:
        return EInputActionOrigin.switch2Capture;
      case 504:
        return EInputActionOrigin.switch2LeftTriggerPull;
      case 505:
        return EInputActionOrigin.switch2LeftTriggerClick;
      case 506:
        return EInputActionOrigin.switch2RightTriggerPull;
      case 507:
        return EInputActionOrigin.switch2RightTriggerClick;
      case 508:
        return EInputActionOrigin.switch2LeftStickMove;
      case 509:
        return EInputActionOrigin.switch2LeftStickClick;
      case 510:
        return EInputActionOrigin.switch2LeftStickDPadNorth;
      case 511:
        return EInputActionOrigin.switch2LeftStickDPadSouth;
      case 512:
        return EInputActionOrigin.switch2LeftStickDPadWest;
      case 513:
        return EInputActionOrigin.switch2LeftStickDPadEast;
      case 514:
        return EInputActionOrigin.switch2RightStickMove;
      case 515:
        return EInputActionOrigin.switch2RightStickClick;
      case 516:
        return EInputActionOrigin.switch2RightStickDPadNorth;
      case 517:
        return EInputActionOrigin.switch2RightStickDPadSouth;
      case 518:
        return EInputActionOrigin.switch2RightStickDPadWest;
      case 519:
        return EInputActionOrigin.switch2RightStickDPadEast;
      case 520:
        return EInputActionOrigin.switch2DPadMove;
      case 521:
        return EInputActionOrigin.switch2DPadNorth;
      case 522:
        return EInputActionOrigin.switch2DPadSouth;
      case 523:
        return EInputActionOrigin.switch2DPadWest;
      case 524:
        return EInputActionOrigin.switch2DPadEast;
      case 525:
        return EInputActionOrigin.switch2ProGyroMove;
      case 526:
        return EInputActionOrigin.switch2ProGyroPitch;
      case 527:
        return EInputActionOrigin.switch2ProGyroYaw;
      case 528:
        return EInputActionOrigin.switch2ProGyroRoll;
      case 529:
        return EInputActionOrigin.switch2GL;
      case 530:
        return EInputActionOrigin.switch2GR;
      case 531:
        return EInputActionOrigin.switch2C;
      case 532:
        return EInputActionOrigin.switch2Reserved1;
      case 533:
        return EInputActionOrigin.switch2Reserved2;
      case 534:
        return EInputActionOrigin.switch2Reserved3;
      case 535:
        return EInputActionOrigin.switch2Reserved4;
      case 536:
        return EInputActionOrigin.switch2Reserved5;
      case 537:
        return EInputActionOrigin.switch2Reserved6;
      case 538:
        return EInputActionOrigin.switch2Reserved7;
      case 539:
        return EInputActionOrigin.switch2Reserved8;
      case 540:
        return EInputActionOrigin.switch2Reserved9;
      case 541:
        return EInputActionOrigin.switch2Reserved10;
      case 542:
        return EInputActionOrigin.steamController2026A;
      case 543:
        return EInputActionOrigin.steamController2026B;
      case 544:
        return EInputActionOrigin.steamController2026X;
      case 545:
        return EInputActionOrigin.steamController2026Y;
      case 546:
        return EInputActionOrigin.steamController2026L1;
      case 547:
        return EInputActionOrigin.steamController2026R1;
      case 548:
        return EInputActionOrigin.steamController2026Menu;
      case 549:
        return EInputActionOrigin.steamController2026View;
      case 550:
        return EInputActionOrigin.steamController2026LeftPadTouch;
      case 551:
        return EInputActionOrigin.steamController2026LeftPadSwipe;
      case 552:
        return EInputActionOrigin.steamController2026LeftPadClick;
      case 553:
        return EInputActionOrigin.steamController2026LeftPadDPadNorth;
      case 554:
        return EInputActionOrigin.steamController2026LeftPadDPadSouth;
      case 555:
        return EInputActionOrigin.steamController2026LeftPadDPadWest;
      case 556:
        return EInputActionOrigin.steamController2026LeftPadDPadEast;
      case 557:
        return EInputActionOrigin.steamController2026RightPadTouch;
      case 558:
        return EInputActionOrigin.steamController2026RightPadSwipe;
      case 559:
        return EInputActionOrigin.steamController2026RightPadClick;
      case 560:
        return EInputActionOrigin.steamController2026RightPadDPadNorth;
      case 561:
        return EInputActionOrigin.steamController2026RightPadDPadSouth;
      case 562:
        return EInputActionOrigin.steamController2026RightPadDPadWest;
      case 563:
        return EInputActionOrigin.steamController2026RightPadDPadEast;
      case 564:
        return EInputActionOrigin.steamController2026L2SoftPull;
      case 565:
        return EInputActionOrigin.steamController2026L2;
      case 566:
        return EInputActionOrigin.steamController2026R2SoftPull;
      case 567:
        return EInputActionOrigin.steamController2026R2;
      case 568:
        return EInputActionOrigin.steamController2026LeftStickMove;
      case 569:
        return EInputActionOrigin.steamController2026L3;
      case 570:
        return EInputActionOrigin.steamController2026LeftStickDPadNorth;
      case 571:
        return EInputActionOrigin.steamController2026LeftStickDPadSouth;
      case 572:
        return EInputActionOrigin.steamController2026LeftStickDPadWest;
      case 573:
        return EInputActionOrigin.steamController2026LeftStickDPadEast;
      case 574:
        return EInputActionOrigin.steamController2026LeftStickTouch;
      case 575:
        return EInputActionOrigin.steamController2026RightStickMove;
      case 576:
        return EInputActionOrigin.steamController2026R3;
      case 577:
        return EInputActionOrigin.steamController2026RightStickDPadNorth;
      case 578:
        return EInputActionOrigin.steamController2026RightStickDPadSouth;
      case 579:
        return EInputActionOrigin.steamController2026RightStickDPadWest;
      case 580:
        return EInputActionOrigin.steamController2026RightStickDPadEast;
      case 581:
        return EInputActionOrigin.steamController2026RightStickTouch;
      case 582:
        return EInputActionOrigin.steamController2026L4;
      case 583:
        return EInputActionOrigin.steamController2026R4;
      case 584:
        return EInputActionOrigin.steamController2026L5;
      case 585:
        return EInputActionOrigin.steamController2026R5;
      case 586:
        return EInputActionOrigin.steamController2026DPadMove;
      case 587:
        return EInputActionOrigin.steamController2026DPadNorth;
      case 588:
        return EInputActionOrigin.steamController2026DPadSouth;
      case 589:
        return EInputActionOrigin.steamController2026DPadWest;
      case 590:
        return EInputActionOrigin.steamController2026DPadEast;
      case 591:
        return EInputActionOrigin.steamController2026GyroMove;
      case 592:
        return EInputActionOrigin.steamController2026GyroPitch;
      case 593:
        return EInputActionOrigin.steamController2026GyroYaw;
      case 594:
        return EInputActionOrigin.steamController2026GyroRoll;
      case 595:
        return EInputActionOrigin.steamController2026LGrip;
      case 596:
        return EInputActionOrigin.steamController2026RGrip;
      case 597:
        return EInputActionOrigin.steamController2026Reserved1;
      case 598:
        return EInputActionOrigin.steamController2026Reserved2;
      case 599:
        return EInputActionOrigin.steamController2026Reserved3;
      case 600:
        return EInputActionOrigin.steamController2026Reserved4;
      case 601:
        return EInputActionOrigin.steamController2026Reserved5;
      case 602:
        return EInputActionOrigin.steamController2026Reserved6;
      case 603:
        return EInputActionOrigin.steamController2026Reserved7;
      case 604:
        return EInputActionOrigin.steamController2026Reserved8;
      case 605:
        return EInputActionOrigin.steamController2026Reserved9;
      case 606:
        return EInputActionOrigin.steamController2026Reserved10;
      case 607:
        return EInputActionOrigin.steamController2026Reserved11;
      case 608:
        return EInputActionOrigin.steamController2026Reserved12;
      case 609:
        return EInputActionOrigin.steamController2026Reserved13;
      case 610:
        return EInputActionOrigin.steamController2026Reserved14;
      case 611:
        return EInputActionOrigin.steamController2026Reserved15;
      case 612:
        return EInputActionOrigin.steamController2026Reserved16;
      case 613:
        return EInputActionOrigin.steamController2026Reserved17;
      case 614:
        return EInputActionOrigin.steamController2026Reserved18;
      case 615:
        return EInputActionOrigin.steamController2026Reserved19;
      case 616:
        return EInputActionOrigin.steamController2026Reserved20;
      case 617:
        return EInputActionOrigin.steamFrameControllerAClick;
      case 618:
        return EInputActionOrigin.steamFrameControllerATouch;
      case 619:
        return EInputActionOrigin.steamFrameControllerBClick;
      case 620:
        return EInputActionOrigin.steamFrameControllerBTouch;
      case 621:
        return EInputActionOrigin.steamFrameControllerXClick;
      case 622:
        return EInputActionOrigin.steamFrameControllerXTouch;
      case 623:
        return EInputActionOrigin.steamFrameControllerYClick;
      case 624:
        return EInputActionOrigin.steamFrameControllerYTouch;
      case 625:
        return EInputActionOrigin.steamFrameControllerLeftTriggerPull;
      case 626:
        return EInputActionOrigin.steamFrameControllerLeftTriggerClick;
      case 627:
        return EInputActionOrigin.steamFrameControllerLeftTriggerTouch;
      case 628:
        return EInputActionOrigin.steamFrameControllerRightTriggerPull;
      case 629:
        return EInputActionOrigin.steamFrameControllerRightTriggerClick;
      case 630:
        return EInputActionOrigin.steamFrameControllerRightTriggerTouch;
      case 631:
        return EInputActionOrigin.steamFrameControllerMenuClick;
      case 632:
        return EInputActionOrigin.steamFrameControllerMenuTouch;
      case 633:
        return EInputActionOrigin.steamFrameControllerViewClick;
      case 634:
        return EInputActionOrigin.steamFrameControllerViewTouch;
      case 635:
        return EInputActionOrigin.steamFrameControllerLeftBumperClick;
      case 636:
        return EInputActionOrigin.steamFrameControllerLeftBumperTouch;
      case 637:
        return EInputActionOrigin.steamFrameControllerRightBumperClick;
      case 638:
        return EInputActionOrigin.steamFrameControllerRightBumperTouch;
      case 639:
        return EInputActionOrigin.steamFrameControllerLeftStickMove;
      case 640:
        return EInputActionOrigin.steamFrameControllerLeftStickClick;
      case 641:
        return EInputActionOrigin.steamFrameControllerLeftStickDPadNorth;
      case 642:
        return EInputActionOrigin.steamFrameControllerLeftStickDPadSouth;
      case 643:
        return EInputActionOrigin.steamFrameControllerLeftStickDPadWest;
      case 644:
        return EInputActionOrigin.steamFrameControllerLeftStickDPadEast;
      case 645:
        return EInputActionOrigin.steamFrameControllerLeftStickTouch;
      case 646:
        return EInputActionOrigin.steamFrameControllerRightStickMove;
      case 647:
        return EInputActionOrigin.steamFrameControllerRightStickClick;
      case 648:
        return EInputActionOrigin.steamFrameControllerRightStickDPadNorth;
      case 649:
        return EInputActionOrigin.steamFrameControllerRightStickDPadSouth;
      case 650:
        return EInputActionOrigin.steamFrameControllerRightStickDPadWest;
      case 651:
        return EInputActionOrigin.steamFrameControllerRightStickDPadEast;
      case 652:
        return EInputActionOrigin.steamFrameControllerRightStickTouch;
      case 653:
        return EInputActionOrigin.steamFrameControllerDPadMove;
      case 654:
        return EInputActionOrigin.steamFrameControllerDPadNorth;
      case 655:
        return EInputActionOrigin.steamFrameControllerDPadSouth;
      case 656:
        return EInputActionOrigin.steamFrameControllerDPadWest;
      case 657:
        return EInputActionOrigin.steamFrameControllerDPadEast;
      case 658:
        return EInputActionOrigin.steamFrameControllerDPadTouch;
      case 659:
        return EInputActionOrigin.steamFrameControllerLeftGyroMove;
      case 660:
        return EInputActionOrigin.steamFrameControllerLeftGyroPitch;
      case 661:
        return EInputActionOrigin.steamFrameControllerLeftGyroYaw;
      case 662:
        return EInputActionOrigin.steamFrameControllerLeftGyroRoll;
      case 663:
        return EInputActionOrigin.steamFrameControllerRightGyroMove;
      case 664:
        return EInputActionOrigin.steamFrameControllerRightGyroPitch;
      case 665:
        return EInputActionOrigin.steamFrameControllerRightGyroYaw;
      case 666:
        return EInputActionOrigin.steamFrameControllerRightGyroRoll;
      case 667:
        return EInputActionOrigin.steamFrameControllerLeftGripPull;
      case 668:
        return EInputActionOrigin.steamFrameControllerLeftGripClick;
      case 669:
        return EInputActionOrigin.steamFrameControllerLeftGripTouch;
      case 670:
        return EInputActionOrigin.steamFrameControllerRightGripPull;
      case 671:
        return EInputActionOrigin.steamFrameControllerRightGripClick;
      case 672:
        return EInputActionOrigin.steamFrameControllerRightGripTouch;
      case 673:
        return EInputActionOrigin.steamFrameControllerLeftThumbrestTouch;
      case 674:
        return EInputActionOrigin.steamFrameControllerRightThumbrestTouch;
      case 675:
        return EInputActionOrigin.steamFrameControllerReserved1;
      case 676:
        return EInputActionOrigin.steamFrameControllerReserved2;
      case 677:
        return EInputActionOrigin.steamFrameControllerReserved3;
      case 678:
        return EInputActionOrigin.steamFrameControllerReserved4;
      case 679:
        return EInputActionOrigin.steamFrameControllerReserved5;
      case 680:
        return EInputActionOrigin.steamFrameControllerReserved6;
      case 681:
        return EInputActionOrigin.steamFrameControllerReserved7;
      case 682:
        return EInputActionOrigin.steamFrameControllerReserved8;
      case 683:
        return EInputActionOrigin.steamFrameControllerReserved9;
      case 684:
        return EInputActionOrigin.steamFrameControllerReserved10;
      case 685:
        return EInputActionOrigin.steamFrameControllerReserved11;
      case 686:
        return EInputActionOrigin.steamFrameControllerReserved12;
      case 687:
        return EInputActionOrigin.steamFrameControllerReserved13;
      case 688:
        return EInputActionOrigin.steamFrameControllerReserved14;
      case 689:
        return EInputActionOrigin.steamFrameControllerReserved15;
      case 690:
        return EInputActionOrigin.steamFrameControllerReserved16;
      case 691:
        return EInputActionOrigin.steamFrameControllerReserved17;
      case 692:
        return EInputActionOrigin.steamFrameControllerReserved18;
      case 693:
        return EInputActionOrigin.steamFrameControllerReserved19;
      case 694:
        return EInputActionOrigin.steamFrameControllerReserved20;
      case 695:
        return EInputActionOrigin.count;
      case 32767:
        return EInputActionOrigin.maximumPossibleValue;
      default:
        throw UnknownEnumValueException(
            "Unknown value for 'EInputActionOrigin'. The value was: '$value'");
    }
  }
}
