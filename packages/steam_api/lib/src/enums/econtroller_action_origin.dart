// ignore_for_file: public_member_api_docs, always_specify_types, avoid_positional_boolean_parameters, avoid_classes_with_only_static_members, unreachable_switch_case
import "dart:ffi";
import "../unknown_enum_value_exception.dart";

typedef EControllerActionOriginAliasDart = int;
typedef EControllerActionOriginAliasC = Int32;

enum EControllerActionOrigin {
  none(0),
  a(1),
  b(2),
  x(3),
  y(4),
  leftBumper(5),
  rightBumper(6),
  leftGrip(7),
  rightGrip(8),
  start(9),
  back(10),
  leftPadTouch(11),
  leftPadSwipe(12),
  leftPadClick(13),
  leftPadDPadNorth(14),
  leftPadDPadSouth(15),
  leftPadDPadWest(16),
  leftPadDPadEast(17),
  rightPadTouch(18),
  rightPadSwipe(19),
  rightPadClick(20),
  rightPadDPadNorth(21),
  rightPadDPadSouth(22),
  rightPadDPadWest(23),
  rightPadDPadEast(24),
  leftTriggerPull(25),
  leftTriggerClick(26),
  rightTriggerPull(27),
  rightTriggerClick(28),
  leftStickMove(29),
  leftStickClick(30),
  leftStickDPadNorth(31),
  leftStickDPadSouth(32),
  leftStickDPadWest(33),
  leftStickDPadEast(34),
  gyroMove(35),
  gyroPitch(36),
  gyroYaw(37),
  gyroRoll(38),
  ps4X(39),
  ps4Circle(40),
  ps4Triangle(41),
  ps4Square(42),
  ps4LeftBumper(43),
  ps4RightBumper(44),
  ps4Options(45),
  ps4Share(46),
  ps4LeftPadTouch(47),
  ps4LeftPadSwipe(48),
  ps4LeftPadClick(49),
  ps4LeftPadDPadNorth(50),
  ps4LeftPadDPadSouth(51),
  ps4LeftPadDPadWest(52),
  ps4LeftPadDPadEast(53),
  ps4RightPadTouch(54),
  ps4RightPadSwipe(55),
  ps4RightPadClick(56),
  ps4RightPadDPadNorth(57),
  ps4RightPadDPadSouth(58),
  ps4RightPadDPadWest(59),
  ps4RightPadDPadEast(60),
  ps4CenterPadTouch(61),
  ps4CenterPadSwipe(62),
  ps4CenterPadClick(63),
  ps4CenterPadDPadNorth(64),
  ps4CenterPadDPadSouth(65),
  ps4CenterPadDPadWest(66),
  ps4CenterPadDPadEast(67),
  ps4LeftTriggerPull(68),
  ps4LeftTriggerClick(69),
  ps4RightTriggerPull(70),
  ps4RightTriggerClick(71),
  ps4LeftStickMove(72),
  ps4LeftStickClick(73),
  ps4LeftStickDPadNorth(74),
  ps4LeftStickDPadSouth(75),
  ps4LeftStickDPadWest(76),
  ps4LeftStickDPadEast(77),
  ps4RightStickMove(78),
  ps4RightStickClick(79),
  ps4RightStickDPadNorth(80),
  ps4RightStickDPadSouth(81),
  ps4RightStickDPadWest(82),
  ps4RightStickDPadEast(83),
  ps4DPadNorth(84),
  ps4DPadSouth(85),
  ps4DPadWest(86),
  ps4DPadEast(87),
  ps4GyroMove(88),
  ps4GyroPitch(89),
  ps4GyroYaw(90),
  ps4GyroRoll(91),
  xBoxOneA(92),
  xBoxOneB(93),
  xBoxOneX(94),
  xBoxOneY(95),
  xBoxOneLeftBumper(96),
  xBoxOneRightBumper(97),
  xBoxOneMenu(98),
  xBoxOneView(99),
  xBoxOneLeftTriggerPull(100),
  xBoxOneLeftTriggerClick(101),
  xBoxOneRightTriggerPull(102),
  xBoxOneRightTriggerClick(103),
  xBoxOneLeftStickMove(104),
  xBoxOneLeftStickClick(105),
  xBoxOneLeftStickDPadNorth(106),
  xBoxOneLeftStickDPadSouth(107),
  xBoxOneLeftStickDPadWest(108),
  xBoxOneLeftStickDPadEast(109),
  xBoxOneRightStickMove(110),
  xBoxOneRightStickClick(111),
  xBoxOneRightStickDPadNorth(112),
  xBoxOneRightStickDPadSouth(113),
  xBoxOneRightStickDPadWest(114),
  xBoxOneRightStickDPadEast(115),
  xBoxOneDPadNorth(116),
  xBoxOneDPadSouth(117),
  xBoxOneDPadWest(118),
  xBoxOneDPadEast(119),
  xBox360A(120),
  xBox360B(121),
  xBox360X(122),
  xBox360Y(123),
  xBox360LeftBumper(124),
  xBox360RightBumper(125),
  xBox360Start(126),
  xBox360Back(127),
  xBox360LeftTriggerPull(128),
  xBox360LeftTriggerClick(129),
  xBox360RightTriggerPull(130),
  xBox360RightTriggerClick(131),
  xBox360LeftStickMove(132),
  xBox360LeftStickClick(133),
  xBox360LeftStickDPadNorth(134),
  xBox360LeftStickDPadSouth(135),
  xBox360LeftStickDPadWest(136),
  xBox360LeftStickDPadEast(137),
  xBox360RightStickMove(138),
  xBox360RightStickClick(139),
  xBox360RightStickDPadNorth(140),
  xBox360RightStickDPadSouth(141),
  xBox360RightStickDPadWest(142),
  xBox360RightStickDPadEast(143),
  xBox360DPadNorth(144),
  xBox360DPadSouth(145),
  xBox360DPadWest(146),
  xBox360DPadEast(147),
  steamV2A(148),
  steamV2B(149),
  steamV2X(150),
  steamV2Y(151),
  steamV2LeftBumper(152),
  steamV2RightBumper(153),
  steamV2LeftGripLower(154),
  steamV2LeftGripUpper(155),
  steamV2RightGripLower(156),
  steamV2RightGripUpper(157),
  steamV2LeftBumperPressure(158),
  steamV2RightBumperPressure(159),
  steamV2LeftGripPressure(160),
  steamV2RightGripPressure(161),
  steamV2LeftGripUpperPressure(162),
  steamV2RightGripUpperPressure(163),
  steamV2Start(164),
  steamV2Back(165),
  steamV2LeftPadTouch(166),
  steamV2LeftPadSwipe(167),
  steamV2LeftPadClick(168),
  steamV2LeftPadPressure(169),
  steamV2LeftPadDPadNorth(170),
  steamV2LeftPadDPadSouth(171),
  steamV2LeftPadDPadWest(172),
  steamV2LeftPadDPadEast(173),
  steamV2RightPadTouch(174),
  steamV2RightPadSwipe(175),
  steamV2RightPadClick(176),
  steamV2RightPadPressure(177),
  steamV2RightPadDPadNorth(178),
  steamV2RightPadDPadSouth(179),
  steamV2RightPadDPadWest(180),
  steamV2RightPadDPadEast(181),
  steamV2LeftTriggerPull(182),
  steamV2LeftTriggerClick(183),
  steamV2RightTriggerPull(184),
  steamV2RightTriggerClick(185),
  steamV2LeftStickMove(186),
  steamV2LeftStickClick(187),
  steamV2LeftStickDPadNorth(188),
  steamV2LeftStickDPadSouth(189),
  steamV2LeftStickDPadWest(190),
  steamV2LeftStickDPadEast(191),
  steamV2GyroMove(192),
  steamV2GyroPitch(193),
  steamV2GyroYaw(194),
  steamV2GyroRoll(195),
  switchA(196),
  switchB(197),
  switchX(198),
  switchY(199),
  switchLeftBumper(200),
  switchRightBumper(201),
  switchPlus(202),
  switchMinus(203),
  switchCapture(204),
  switchLeftTriggerPull(205),
  switchLeftTriggerClick(206),
  switchRightTriggerPull(207),
  switchRightTriggerClick(208),
  switchLeftStickMove(209),
  switchLeftStickClick(210),
  switchLeftStickDPadNorth(211),
  switchLeftStickDPadSouth(212),
  switchLeftStickDPadWest(213),
  switchLeftStickDPadEast(214),
  switchRightStickMove(215),
  switchRightStickClick(216),
  switchRightStickDPadNorth(217),
  switchRightStickDPadSouth(218),
  switchRightStickDPadWest(219),
  switchRightStickDPadEast(220),
  switchDPadNorth(221),
  switchDPadSouth(222),
  switchDPadWest(223),
  switchDPadEast(224),
  switchProGyroMove(225),
  switchProGyroPitch(226),
  switchProGyroYaw(227),
  switchProGyroRoll(228),
  switchRightGyroMove(229),
  switchRightGyroPitch(230),
  switchRightGyroYaw(231),
  switchRightGyroRoll(232),
  switchLeftGyroMove(233),
  switchLeftGyroPitch(234),
  switchLeftGyroYaw(235),
  switchLeftGyroRoll(236),
  switchLeftGripLower(237),
  switchLeftGripUpper(238),
  switchRightGripLower(239),
  switchRightGripUpper(240),
  ps4DPadMove(241),
  xBoxOneDPadMove(242),
  xBox360DPadMove(243),
  switchDPadMove(244),
  ps5X(245),
  ps5Circle(246),
  ps5Triangle(247),
  ps5Square(248),
  ps5LeftBumper(249),
  ps5RightBumper(250),
  ps5Option(251),
  ps5Create(252),
  ps5Mute(253),
  ps5LeftPadTouch(254),
  ps5LeftPadSwipe(255),
  ps5LeftPadClick(256),
  ps5LeftPadDPadNorth(257),
  ps5LeftPadDPadSouth(258),
  ps5LeftPadDPadWest(259),
  ps5LeftPadDPadEast(260),
  ps5RightPadTouch(261),
  ps5RightPadSwipe(262),
  ps5RightPadClick(263),
  ps5RightPadDPadNorth(264),
  ps5RightPadDPadSouth(265),
  ps5RightPadDPadWest(266),
  ps5RightPadDPadEast(267),
  ps5CenterPadTouch(268),
  ps5CenterPadSwipe(269),
  ps5CenterPadClick(270),
  ps5CenterPadDPadNorth(271),
  ps5CenterPadDPadSouth(272),
  ps5CenterPadDPadWest(273),
  ps5CenterPadDPadEast(274),
  ps5LeftTriggerPull(275),
  ps5LeftTriggerClick(276),
  ps5RightTriggerPull(277),
  ps5RightTriggerClick(278),
  ps5LeftStickMove(279),
  ps5LeftStickClick(280),
  ps5LeftStickDPadNorth(281),
  ps5LeftStickDPadSouth(282),
  ps5LeftStickDPadWest(283),
  ps5LeftStickDPadEast(284),
  ps5RightStickMove(285),
  ps5RightStickClick(286),
  ps5RightStickDPadNorth(287),
  ps5RightStickDPadSouth(288),
  ps5RightStickDPadWest(289),
  ps5RightStickDPadEast(290),
  ps5DPadMove(291),
  ps5DPadNorth(292),
  ps5DPadSouth(293),
  ps5DPadWest(294),
  ps5DPadEast(295),
  ps5GyroMove(296),
  ps5GyroPitch(297),
  ps5GyroYaw(298),
  ps5GyroRoll(299),
  xBoxOneLeftGripLower(300),
  xBoxOneLeftGripUpper(301),
  xBoxOneRightGripLower(302),
  xBoxOneRightGripUpper(303),
  xBoxOneShare(304),
  steamDeckA(305),
  steamDeckB(306),
  steamDeckX(307),
  steamDeckY(308),
  steamDeckL1(309),
  steamDeckR1(310),
  steamDeckMenu(311),
  steamDeckView(312),
  steamDeckLeftPadTouch(313),
  steamDeckLeftPadSwipe(314),
  steamDeckLeftPadClick(315),
  steamDeckLeftPadDPadNorth(316),
  steamDeckLeftPadDPadSouth(317),
  steamDeckLeftPadDPadWest(318),
  steamDeckLeftPadDPadEast(319),
  steamDeckRightPadTouch(320),
  steamDeckRightPadSwipe(321),
  steamDeckRightPadClick(322),
  steamDeckRightPadDPadNorth(323),
  steamDeckRightPadDPadSouth(324),
  steamDeckRightPadDPadWest(325),
  steamDeckRightPadDPadEast(326),
  steamDeckL2SoftPull(327),
  steamDeckL2(328),
  steamDeckR2SoftPull(329),
  steamDeckR2(330),
  steamDeckLeftStickMove(331),
  steamDeckL3(332),
  steamDeckLeftStickDPadNorth(333),
  steamDeckLeftStickDPadSouth(334),
  steamDeckLeftStickDPadWest(335),
  steamDeckLeftStickDPadEast(336),
  steamDeckLeftStickTouch(337),
  steamDeckRightStickMove(338),
  steamDeckR3(339),
  steamDeckRightStickDPadNorth(340),
  steamDeckRightStickDPadSouth(341),
  steamDeckRightStickDPadWest(342),
  steamDeckRightStickDPadEast(343),
  steamDeckRightStickTouch(344),
  steamDeckL4(345),
  steamDeckR4(346),
  steamDeckL5(347),
  steamDeckR5(348),
  steamDeckDPadMove(349),
  steamDeckDPadNorth(350),
  steamDeckDPadSouth(351),
  steamDeckDPadWest(352),
  steamDeckDPadEast(353),
  steamDeckGyroMove(354),
  steamDeckGyroPitch(355),
  steamDeckGyroYaw(356),
  steamDeckGyroRoll(357),
  steamDeckReserved1(358),
  steamDeckReserved2(359),
  steamDeckReserved3(360),
  steamDeckReserved4(361),
  steamDeckReserved5(362),
  steamDeckReserved6(363),
  steamDeckReserved7(364),
  steamDeckReserved8(365),
  steamDeckReserved9(366),
  steamDeckReserved10(367),
  steamDeckReserved11(368),
  steamDeckReserved12(369),
  steamDeckReserved13(370),
  steamDeckReserved14(371),
  steamDeckReserved15(372),
  steamDeckReserved16(373),
  steamDeckReserved17(374),
  steamDeckReserved18(375),
  steamDeckReserved19(376),
  steamDeckReserved20(377),
  switchJoyConButtonN(378),
  switchJoyConButtonE(379),
  switchJoyConButtonS(380),
  switchJoyConButtonW(381),
  ps5LeftGrip(382),
  ps5RightGrip(383),
  ps5LeftFn(384),
  ps5RightFn(385),
  horipadM1(386),
  horipadM2(387),
  horipadL4(388),
  horipadR4(389),
  lenovoLegionGoA(390),
  lenovoLegionGoB(391),
  lenovoLegionGoX(392),
  lenovoLegionGoY(393),
  lenovoLegionGoLB(394),
  lenovoLegionGoRB(395),
  lenovoLegionGoMenu(396),
  lenovoLegionGoView(397),
  lenovoLegionGoLeftPadTouch(398),
  lenovoLegionGoLeftPadSwipe(399),
  lenovoLegionGoLeftPadClick(400),
  lenovoLegionGoLeftPadDPadNorth(401),
  lenovoLegionGoLeftPadDPadSouth(402),
  lenovoLegionGoLeftPadDPadWest(403),
  lenovoLegionGoLeftPadDPadEast(404),
  lenovoLegionGoRightPadTouch(405),
  lenovoLegionGoRightPadSwipe(406),
  lenovoLegionGoRightPadClick(407),
  lenovoLegionGoRightPadDPadNorth(408),
  lenovoLegionGoRightPadDPadSouth(409),
  lenovoLegionGoRightPadDPadWest(410),
  lenovoLegionGoRightPadDPadEast(411),
  lenovoLegionGoLTSoftPull(412),
  lenovoLegionGoLT(413),
  lenovoLegionGoRTSoftPull(414),
  lenovoLegionGoRT(415),
  lenovoLegionGoLeftStickMove(416),
  lenovoLegionGoLS(417),
  lenovoLegionGoLeftStickDPadNorth(418),
  lenovoLegionGoLeftStickDPadSouth(419),
  lenovoLegionGoLeftStickDPadWest(420),
  lenovoLegionGoLeftStickDPadEast(421),
  lenovoLegionGoRightStickMove(422),
  lenovoLegionGoRS(423),
  lenovoLegionGoRightStickDPadNorth(424),
  lenovoLegionGoRightStickDPadSouth(425),
  lenovoLegionGoRightStickDPadWest(426),
  lenovoLegionGoRightStickDPadEast(427),
  lenovoLegionGoY1(428),
  lenovoLegionGoY2(429),
  lenovoLegionGoDPadMove(430),
  lenovoLegionGoDPadNorth(431),
  lenovoLegionGoDPadSouth(432),
  lenovoLegionGoDPadWest(433),
  lenovoLegionGoDPadEast(434),
  lenovoLegionGoGyroMove(435),
  lenovoLegionGoGyroPitch(436),
  lenovoLegionGoGyroYaw(437),
  lenovoLegionGoGyroRoll(438),
  lenovoLegionGoReserved1(439),
  lenovoLegionGoReserved2(440),
  lenovoLegionGoReserved3(441),
  lenovoLegionGoReserved4(442),
  lenovoLegionGoReserved5(443),
  lenovoLegionGoReserved6(444),
  lenovoLegionGoReserved7(445),
  lenovoLegionGoReserved8(446),
  lenovoLegionGoReserved9(447),
  lenovoLegionGoReserved10(448),
  lenovoLegionGoReserved11(449),
  lenovoLegionGoReserved12(450),
  lenovoLegionGoReserved13(451),
  lenovoLegionGoReserved14(452),
  lenovoLegionGoReserved15(453),
  lenovoLegionGoReserved16(454),
  lenovoLegionGoReserved17(455),
  lenovoLegionGoReserved18(456),
  lenovoLegionGoReserved19(457),
  lenovoLegionGoReserved20(458),
  genericL4(459),
  genericR4(460),
  genericL5(461),
  genericR5(462),
  genericPL(463),
  genericPR(464),
  genericC(465),
  genericZ(466),
  genericMISC1(467),
  genericMISC2(468),
  genericMISC3(469),
  genericMISC4(470),
  genericMISC5(471),
  genericMISC6(472),
  genericMISC7(473),
  genericMISC8(474),
  switch2A(475),
  switch2B(476),
  switch2X(477),
  switch2Y(478),
  switch2LeftBumper(479),
  switch2RightBumper(480),
  switch2Plus(481),
  switch2Minus(482),
  switch2Capture(483),
  switch2LeftTriggerPull(484),
  switch2LeftTriggerClick(485),
  switch2RightTriggerPull(486),
  switch2RightTriggerClick(487),
  switch2LeftStickMove(488),
  switch2LeftStickClick(489),
  switch2LeftStickDPadNorth(490),
  switch2LeftStickDPadSouth(491),
  switch2LeftStickDPadWest(492),
  switch2LeftStickDPadEast(493),
  switch2RightStickMove(494),
  switch2RightStickClick(495),
  switch2RightStickDPadNorth(496),
  switch2RightStickDPadSouth(497),
  switch2RightStickDPadWest(498),
  switch2RightStickDPadEast(499),
  switch2DPadMove(500),
  switch2DPadNorth(501),
  switch2DPadSouth(502),
  switch2DPadWest(503),
  switch2DPadEast(504),
  switch2ProGyroMove(505),
  switch2ProGyroPitch(506),
  switch2ProGyroYaw(507),
  switch2ProGyroRoll(508),
  switch2GL(509),
  switch2GR(510),
  switch2C(511),
  switch2Reserved1(512),
  switch2Reserved2(513),
  switch2Reserved3(514),
  switch2Reserved4(515),
  switch2Reserved5(516),
  switch2Reserved6(517),
  switch2Reserved7(518),
  switch2Reserved8(519),
  switch2Reserved9(520),
  switch2Reserved10(521),
  steamController2026A(522),
  steamController2026B(523),
  steamController2026X(524),
  steamController2026Y(525),
  steamController2026L1(526),
  steamController2026R1(527),
  steamController2026Menu(528),
  steamController2026View(529),
  steamController2026LeftPadTouch(530),
  steamController2026LeftPadSwipe(531),
  steamController2026LeftPadClick(532),
  steamController2026LeftPadDPadNorth(533),
  steamController2026LeftPadDPadSouth(534),
  steamController2026LeftPadDPadWest(535),
  steamController2026LeftPadDPadEast(536),
  steamController2026RightPadTouch(537),
  steamController2026RightPadSwipe(538),
  steamController2026RightPadClick(539),
  steamController2026RightPadDPadNorth(540),
  steamController2026RightPadDPadSouth(541),
  steamController2026RightPadDPadWest(542),
  steamController2026RightPadDPadEast(543),
  steamController2026L2SoftPull(544),
  steamController2026L2(545),
  steamController2026R2SoftPull(546),
  steamController2026R2(547),
  steamController2026LeftStickMove(548),
  steamController2026L3(549),
  steamController2026LeftStickDPadNorth(550),
  steamController2026LeftStickDPadSouth(551),
  steamController2026LeftStickDPadWest(552),
  steamController2026LeftStickDPadEast(553),
  steamController2026LeftStickTouch(554),
  steamController2026RightStickMove(555),
  steamController2026R3(556),
  steamController2026RightStickDPadNorth(557),
  steamController2026RightStickDPadSouth(558),
  steamController2026RightStickDPadWest(559),
  steamController2026RightStickDPadEast(560),
  steamController2026RightStickTouch(561),
  steamController2026L4(562),
  steamController2026R4(563),
  steamController2026L5(564),
  steamController2026R5(565),
  steamController2026DPadMove(566),
  steamController2026DPadNorth(567),
  steamController2026DPadSouth(568),
  steamController2026DPadWest(569),
  steamController2026DPadEast(570),
  steamController2026GyroMove(571),
  steamController2026GyroPitch(572),
  steamController2026GyroYaw(573),
  steamController2026GyroRoll(574),
  steamController2026LGrip(575),
  steamController2026RGrip(576),
  steamController2026Reserved1(577),
  steamController2026Reserved2(578),
  steamController2026Reserved3(579),
  steamController2026Reserved4(580),
  steamController2026Reserved5(581),
  steamController2026Reserved6(582),
  steamController2026Reserved7(583),
  steamController2026Reserved8(584),
  steamController2026Reserved9(585),
  steamController2026Reserved10(586),
  steamController2026Reserved11(587),
  steamController2026Reserved12(588),
  steamController2026Reserved13(589),
  steamController2026Reserved14(590),
  steamController2026Reserved15(591),
  steamController2026Reserved16(592),
  steamController2026Reserved17(593),
  steamController2026Reserved18(594),
  steamController2026Reserved19(595),
  steamController2026Reserved20(596),
  steamFrameControllerAClick(597),
  steamFrameControllerATouch(598),
  steamFrameControllerBClick(599),
  steamFrameControllerBTouch(600),
  steamFrameControllerXClick(601),
  steamFrameControllerXTouch(602),
  steamFrameControllerYClick(603),
  steamFrameControllerYTouch(604),
  steamFrameControllerLeftTriggerPull(605),
  steamFrameControllerLeftTriggerClick(606),
  steamFrameControllerLeftTriggerTouch(607),
  steamFrameControllerRightTriggerPull(608),
  steamFrameControllerRightTriggerClick(609),
  steamFrameControllerRightTriggerTouch(610),
  steamFrameControllerMenuClick(611),
  steamFrameControllerMenuTouch(612),
  steamFrameControllerViewClick(613),
  steamFrameControllerViewTouch(614),
  steamFrameControllerLeftBumperClick(615),
  steamFrameControllerLeftBumperTouch(616),
  steamFrameControllerRightBumperClick(617),
  steamFrameControllerRightBumperTouch(618),
  steamFrameControllerLeftStickMove(619),
  steamFrameControllerLeftStickClick(620),
  steamFrameControllerLeftStickDPadNorth(621),
  steamFrameControllerLeftStickDPadSouth(622),
  steamFrameControllerLeftStickDPadWest(623),
  steamFrameControllerLeftStickDPadEast(624),
  steamFrameControllerLeftStickTouch(625),
  steamFrameControllerRightStickMove(626),
  steamFrameControllerRightStickClick(627),
  steamFrameControllerRightStickDPadNorth(628),
  steamFrameControllerRightStickDPadSouth(629),
  steamFrameControllerRightStickDPadWest(630),
  steamFrameControllerRightStickDPadEast(631),
  steamFrameControllerRightStickTouch(632),
  steamFrameControllerDPadMove(633),
  steamFrameControllerDPadNorth(634),
  steamFrameControllerDPadSouth(635),
  steamFrameControllerDPadWest(636),
  steamFrameControllerDPadEast(637),
  steamFrameControllerDPadTouch(638),
  steamFrameControllerLeftGyroMove(639),
  steamFrameControllerLeftGyroPitch(640),
  steamFrameControllerLeftGyroYaw(641),
  steamFrameControllerLeftGyroRoll(642),
  steamFrameControllerRightGyroMove(643),
  steamFrameControllerRightGyroPitch(644),
  steamFrameControllerRightGyroYaw(645),
  steamFrameControllerRightGyroRoll(646),
  steamFrameControllerLeftGripPull(647),
  steamFrameControllerLeftGripClick(648),
  steamFrameControllerLeftGripTouch(649),
  steamFrameControllerRightGripPull(650),
  steamFrameControllerRightGripClick(651),
  steamFrameControllerRightGripTouch(652),
  steamFrameControllerLeftThumbrestTouch(653),
  steamFrameControllerRightThumbrestTouch(654),
  steamFrameControllerReserved1(655),
  steamFrameControllerReserved2(656),
  steamFrameControllerReserved3(657),
  steamFrameControllerReserved4(658),
  steamFrameControllerReserved5(659),
  steamFrameControllerReserved6(660),
  steamFrameControllerReserved7(661),
  steamFrameControllerReserved8(662),
  steamFrameControllerReserved9(663),
  steamFrameControllerReserved10(664),
  steamFrameControllerReserved11(665),
  steamFrameControllerReserved12(666),
  steamFrameControllerReserved13(667),
  steamFrameControllerReserved14(668),
  steamFrameControllerReserved15(669),
  steamFrameControllerReserved16(670),
  steamFrameControllerReserved17(671),
  steamFrameControllerReserved18(672),
  steamFrameControllerReserved19(673),
  steamFrameControllerReserved20(674),
  count(675),
  maximumPossibleValue(32767),
  ;

  final int value;

  const EControllerActionOrigin(this.value);

  factory EControllerActionOrigin.fromValue(int value) {
    switch (value) {
      case 0:
        return EControllerActionOrigin.none;
      case 1:
        return EControllerActionOrigin.a;
      case 2:
        return EControllerActionOrigin.b;
      case 3:
        return EControllerActionOrigin.x;
      case 4:
        return EControllerActionOrigin.y;
      case 5:
        return EControllerActionOrigin.leftBumper;
      case 6:
        return EControllerActionOrigin.rightBumper;
      case 7:
        return EControllerActionOrigin.leftGrip;
      case 8:
        return EControllerActionOrigin.rightGrip;
      case 9:
        return EControllerActionOrigin.start;
      case 10:
        return EControllerActionOrigin.back;
      case 11:
        return EControllerActionOrigin.leftPadTouch;
      case 12:
        return EControllerActionOrigin.leftPadSwipe;
      case 13:
        return EControllerActionOrigin.leftPadClick;
      case 14:
        return EControllerActionOrigin.leftPadDPadNorth;
      case 15:
        return EControllerActionOrigin.leftPadDPadSouth;
      case 16:
        return EControllerActionOrigin.leftPadDPadWest;
      case 17:
        return EControllerActionOrigin.leftPadDPadEast;
      case 18:
        return EControllerActionOrigin.rightPadTouch;
      case 19:
        return EControllerActionOrigin.rightPadSwipe;
      case 20:
        return EControllerActionOrigin.rightPadClick;
      case 21:
        return EControllerActionOrigin.rightPadDPadNorth;
      case 22:
        return EControllerActionOrigin.rightPadDPadSouth;
      case 23:
        return EControllerActionOrigin.rightPadDPadWest;
      case 24:
        return EControllerActionOrigin.rightPadDPadEast;
      case 25:
        return EControllerActionOrigin.leftTriggerPull;
      case 26:
        return EControllerActionOrigin.leftTriggerClick;
      case 27:
        return EControllerActionOrigin.rightTriggerPull;
      case 28:
        return EControllerActionOrigin.rightTriggerClick;
      case 29:
        return EControllerActionOrigin.leftStickMove;
      case 30:
        return EControllerActionOrigin.leftStickClick;
      case 31:
        return EControllerActionOrigin.leftStickDPadNorth;
      case 32:
        return EControllerActionOrigin.leftStickDPadSouth;
      case 33:
        return EControllerActionOrigin.leftStickDPadWest;
      case 34:
        return EControllerActionOrigin.leftStickDPadEast;
      case 35:
        return EControllerActionOrigin.gyroMove;
      case 36:
        return EControllerActionOrigin.gyroPitch;
      case 37:
        return EControllerActionOrigin.gyroYaw;
      case 38:
        return EControllerActionOrigin.gyroRoll;
      case 39:
        return EControllerActionOrigin.ps4X;
      case 40:
        return EControllerActionOrigin.ps4Circle;
      case 41:
        return EControllerActionOrigin.ps4Triangle;
      case 42:
        return EControllerActionOrigin.ps4Square;
      case 43:
        return EControllerActionOrigin.ps4LeftBumper;
      case 44:
        return EControllerActionOrigin.ps4RightBumper;
      case 45:
        return EControllerActionOrigin.ps4Options;
      case 46:
        return EControllerActionOrigin.ps4Share;
      case 47:
        return EControllerActionOrigin.ps4LeftPadTouch;
      case 48:
        return EControllerActionOrigin.ps4LeftPadSwipe;
      case 49:
        return EControllerActionOrigin.ps4LeftPadClick;
      case 50:
        return EControllerActionOrigin.ps4LeftPadDPadNorth;
      case 51:
        return EControllerActionOrigin.ps4LeftPadDPadSouth;
      case 52:
        return EControllerActionOrigin.ps4LeftPadDPadWest;
      case 53:
        return EControllerActionOrigin.ps4LeftPadDPadEast;
      case 54:
        return EControllerActionOrigin.ps4RightPadTouch;
      case 55:
        return EControllerActionOrigin.ps4RightPadSwipe;
      case 56:
        return EControllerActionOrigin.ps4RightPadClick;
      case 57:
        return EControllerActionOrigin.ps4RightPadDPadNorth;
      case 58:
        return EControllerActionOrigin.ps4RightPadDPadSouth;
      case 59:
        return EControllerActionOrigin.ps4RightPadDPadWest;
      case 60:
        return EControllerActionOrigin.ps4RightPadDPadEast;
      case 61:
        return EControllerActionOrigin.ps4CenterPadTouch;
      case 62:
        return EControllerActionOrigin.ps4CenterPadSwipe;
      case 63:
        return EControllerActionOrigin.ps4CenterPadClick;
      case 64:
        return EControllerActionOrigin.ps4CenterPadDPadNorth;
      case 65:
        return EControllerActionOrigin.ps4CenterPadDPadSouth;
      case 66:
        return EControllerActionOrigin.ps4CenterPadDPadWest;
      case 67:
        return EControllerActionOrigin.ps4CenterPadDPadEast;
      case 68:
        return EControllerActionOrigin.ps4LeftTriggerPull;
      case 69:
        return EControllerActionOrigin.ps4LeftTriggerClick;
      case 70:
        return EControllerActionOrigin.ps4RightTriggerPull;
      case 71:
        return EControllerActionOrigin.ps4RightTriggerClick;
      case 72:
        return EControllerActionOrigin.ps4LeftStickMove;
      case 73:
        return EControllerActionOrigin.ps4LeftStickClick;
      case 74:
        return EControllerActionOrigin.ps4LeftStickDPadNorth;
      case 75:
        return EControllerActionOrigin.ps4LeftStickDPadSouth;
      case 76:
        return EControllerActionOrigin.ps4LeftStickDPadWest;
      case 77:
        return EControllerActionOrigin.ps4LeftStickDPadEast;
      case 78:
        return EControllerActionOrigin.ps4RightStickMove;
      case 79:
        return EControllerActionOrigin.ps4RightStickClick;
      case 80:
        return EControllerActionOrigin.ps4RightStickDPadNorth;
      case 81:
        return EControllerActionOrigin.ps4RightStickDPadSouth;
      case 82:
        return EControllerActionOrigin.ps4RightStickDPadWest;
      case 83:
        return EControllerActionOrigin.ps4RightStickDPadEast;
      case 84:
        return EControllerActionOrigin.ps4DPadNorth;
      case 85:
        return EControllerActionOrigin.ps4DPadSouth;
      case 86:
        return EControllerActionOrigin.ps4DPadWest;
      case 87:
        return EControllerActionOrigin.ps4DPadEast;
      case 88:
        return EControllerActionOrigin.ps4GyroMove;
      case 89:
        return EControllerActionOrigin.ps4GyroPitch;
      case 90:
        return EControllerActionOrigin.ps4GyroYaw;
      case 91:
        return EControllerActionOrigin.ps4GyroRoll;
      case 92:
        return EControllerActionOrigin.xBoxOneA;
      case 93:
        return EControllerActionOrigin.xBoxOneB;
      case 94:
        return EControllerActionOrigin.xBoxOneX;
      case 95:
        return EControllerActionOrigin.xBoxOneY;
      case 96:
        return EControllerActionOrigin.xBoxOneLeftBumper;
      case 97:
        return EControllerActionOrigin.xBoxOneRightBumper;
      case 98:
        return EControllerActionOrigin.xBoxOneMenu;
      case 99:
        return EControllerActionOrigin.xBoxOneView;
      case 100:
        return EControllerActionOrigin.xBoxOneLeftTriggerPull;
      case 101:
        return EControllerActionOrigin.xBoxOneLeftTriggerClick;
      case 102:
        return EControllerActionOrigin.xBoxOneRightTriggerPull;
      case 103:
        return EControllerActionOrigin.xBoxOneRightTriggerClick;
      case 104:
        return EControllerActionOrigin.xBoxOneLeftStickMove;
      case 105:
        return EControllerActionOrigin.xBoxOneLeftStickClick;
      case 106:
        return EControllerActionOrigin.xBoxOneLeftStickDPadNorth;
      case 107:
        return EControllerActionOrigin.xBoxOneLeftStickDPadSouth;
      case 108:
        return EControllerActionOrigin.xBoxOneLeftStickDPadWest;
      case 109:
        return EControllerActionOrigin.xBoxOneLeftStickDPadEast;
      case 110:
        return EControllerActionOrigin.xBoxOneRightStickMove;
      case 111:
        return EControllerActionOrigin.xBoxOneRightStickClick;
      case 112:
        return EControllerActionOrigin.xBoxOneRightStickDPadNorth;
      case 113:
        return EControllerActionOrigin.xBoxOneRightStickDPadSouth;
      case 114:
        return EControllerActionOrigin.xBoxOneRightStickDPadWest;
      case 115:
        return EControllerActionOrigin.xBoxOneRightStickDPadEast;
      case 116:
        return EControllerActionOrigin.xBoxOneDPadNorth;
      case 117:
        return EControllerActionOrigin.xBoxOneDPadSouth;
      case 118:
        return EControllerActionOrigin.xBoxOneDPadWest;
      case 119:
        return EControllerActionOrigin.xBoxOneDPadEast;
      case 120:
        return EControllerActionOrigin.xBox360A;
      case 121:
        return EControllerActionOrigin.xBox360B;
      case 122:
        return EControllerActionOrigin.xBox360X;
      case 123:
        return EControllerActionOrigin.xBox360Y;
      case 124:
        return EControllerActionOrigin.xBox360LeftBumper;
      case 125:
        return EControllerActionOrigin.xBox360RightBumper;
      case 126:
        return EControllerActionOrigin.xBox360Start;
      case 127:
        return EControllerActionOrigin.xBox360Back;
      case 128:
        return EControllerActionOrigin.xBox360LeftTriggerPull;
      case 129:
        return EControllerActionOrigin.xBox360LeftTriggerClick;
      case 130:
        return EControllerActionOrigin.xBox360RightTriggerPull;
      case 131:
        return EControllerActionOrigin.xBox360RightTriggerClick;
      case 132:
        return EControllerActionOrigin.xBox360LeftStickMove;
      case 133:
        return EControllerActionOrigin.xBox360LeftStickClick;
      case 134:
        return EControllerActionOrigin.xBox360LeftStickDPadNorth;
      case 135:
        return EControllerActionOrigin.xBox360LeftStickDPadSouth;
      case 136:
        return EControllerActionOrigin.xBox360LeftStickDPadWest;
      case 137:
        return EControllerActionOrigin.xBox360LeftStickDPadEast;
      case 138:
        return EControllerActionOrigin.xBox360RightStickMove;
      case 139:
        return EControllerActionOrigin.xBox360RightStickClick;
      case 140:
        return EControllerActionOrigin.xBox360RightStickDPadNorth;
      case 141:
        return EControllerActionOrigin.xBox360RightStickDPadSouth;
      case 142:
        return EControllerActionOrigin.xBox360RightStickDPadWest;
      case 143:
        return EControllerActionOrigin.xBox360RightStickDPadEast;
      case 144:
        return EControllerActionOrigin.xBox360DPadNorth;
      case 145:
        return EControllerActionOrigin.xBox360DPadSouth;
      case 146:
        return EControllerActionOrigin.xBox360DPadWest;
      case 147:
        return EControllerActionOrigin.xBox360DPadEast;
      case 148:
        return EControllerActionOrigin.steamV2A;
      case 149:
        return EControllerActionOrigin.steamV2B;
      case 150:
        return EControllerActionOrigin.steamV2X;
      case 151:
        return EControllerActionOrigin.steamV2Y;
      case 152:
        return EControllerActionOrigin.steamV2LeftBumper;
      case 153:
        return EControllerActionOrigin.steamV2RightBumper;
      case 154:
        return EControllerActionOrigin.steamV2LeftGripLower;
      case 155:
        return EControllerActionOrigin.steamV2LeftGripUpper;
      case 156:
        return EControllerActionOrigin.steamV2RightGripLower;
      case 157:
        return EControllerActionOrigin.steamV2RightGripUpper;
      case 158:
        return EControllerActionOrigin.steamV2LeftBumperPressure;
      case 159:
        return EControllerActionOrigin.steamV2RightBumperPressure;
      case 160:
        return EControllerActionOrigin.steamV2LeftGripPressure;
      case 161:
        return EControllerActionOrigin.steamV2RightGripPressure;
      case 162:
        return EControllerActionOrigin.steamV2LeftGripUpperPressure;
      case 163:
        return EControllerActionOrigin.steamV2RightGripUpperPressure;
      case 164:
        return EControllerActionOrigin.steamV2Start;
      case 165:
        return EControllerActionOrigin.steamV2Back;
      case 166:
        return EControllerActionOrigin.steamV2LeftPadTouch;
      case 167:
        return EControllerActionOrigin.steamV2LeftPadSwipe;
      case 168:
        return EControllerActionOrigin.steamV2LeftPadClick;
      case 169:
        return EControllerActionOrigin.steamV2LeftPadPressure;
      case 170:
        return EControllerActionOrigin.steamV2LeftPadDPadNorth;
      case 171:
        return EControllerActionOrigin.steamV2LeftPadDPadSouth;
      case 172:
        return EControllerActionOrigin.steamV2LeftPadDPadWest;
      case 173:
        return EControllerActionOrigin.steamV2LeftPadDPadEast;
      case 174:
        return EControllerActionOrigin.steamV2RightPadTouch;
      case 175:
        return EControllerActionOrigin.steamV2RightPadSwipe;
      case 176:
        return EControllerActionOrigin.steamV2RightPadClick;
      case 177:
        return EControllerActionOrigin.steamV2RightPadPressure;
      case 178:
        return EControllerActionOrigin.steamV2RightPadDPadNorth;
      case 179:
        return EControllerActionOrigin.steamV2RightPadDPadSouth;
      case 180:
        return EControllerActionOrigin.steamV2RightPadDPadWest;
      case 181:
        return EControllerActionOrigin.steamV2RightPadDPadEast;
      case 182:
        return EControllerActionOrigin.steamV2LeftTriggerPull;
      case 183:
        return EControllerActionOrigin.steamV2LeftTriggerClick;
      case 184:
        return EControllerActionOrigin.steamV2RightTriggerPull;
      case 185:
        return EControllerActionOrigin.steamV2RightTriggerClick;
      case 186:
        return EControllerActionOrigin.steamV2LeftStickMove;
      case 187:
        return EControllerActionOrigin.steamV2LeftStickClick;
      case 188:
        return EControllerActionOrigin.steamV2LeftStickDPadNorth;
      case 189:
        return EControllerActionOrigin.steamV2LeftStickDPadSouth;
      case 190:
        return EControllerActionOrigin.steamV2LeftStickDPadWest;
      case 191:
        return EControllerActionOrigin.steamV2LeftStickDPadEast;
      case 192:
        return EControllerActionOrigin.steamV2GyroMove;
      case 193:
        return EControllerActionOrigin.steamV2GyroPitch;
      case 194:
        return EControllerActionOrigin.steamV2GyroYaw;
      case 195:
        return EControllerActionOrigin.steamV2GyroRoll;
      case 196:
        return EControllerActionOrigin.switchA;
      case 197:
        return EControllerActionOrigin.switchB;
      case 198:
        return EControllerActionOrigin.switchX;
      case 199:
        return EControllerActionOrigin.switchY;
      case 200:
        return EControllerActionOrigin.switchLeftBumper;
      case 201:
        return EControllerActionOrigin.switchRightBumper;
      case 202:
        return EControllerActionOrigin.switchPlus;
      case 203:
        return EControllerActionOrigin.switchMinus;
      case 204:
        return EControllerActionOrigin.switchCapture;
      case 205:
        return EControllerActionOrigin.switchLeftTriggerPull;
      case 206:
        return EControllerActionOrigin.switchLeftTriggerClick;
      case 207:
        return EControllerActionOrigin.switchRightTriggerPull;
      case 208:
        return EControllerActionOrigin.switchRightTriggerClick;
      case 209:
        return EControllerActionOrigin.switchLeftStickMove;
      case 210:
        return EControllerActionOrigin.switchLeftStickClick;
      case 211:
        return EControllerActionOrigin.switchLeftStickDPadNorth;
      case 212:
        return EControllerActionOrigin.switchLeftStickDPadSouth;
      case 213:
        return EControllerActionOrigin.switchLeftStickDPadWest;
      case 214:
        return EControllerActionOrigin.switchLeftStickDPadEast;
      case 215:
        return EControllerActionOrigin.switchRightStickMove;
      case 216:
        return EControllerActionOrigin.switchRightStickClick;
      case 217:
        return EControllerActionOrigin.switchRightStickDPadNorth;
      case 218:
        return EControllerActionOrigin.switchRightStickDPadSouth;
      case 219:
        return EControllerActionOrigin.switchRightStickDPadWest;
      case 220:
        return EControllerActionOrigin.switchRightStickDPadEast;
      case 221:
        return EControllerActionOrigin.switchDPadNorth;
      case 222:
        return EControllerActionOrigin.switchDPadSouth;
      case 223:
        return EControllerActionOrigin.switchDPadWest;
      case 224:
        return EControllerActionOrigin.switchDPadEast;
      case 225:
        return EControllerActionOrigin.switchProGyroMove;
      case 226:
        return EControllerActionOrigin.switchProGyroPitch;
      case 227:
        return EControllerActionOrigin.switchProGyroYaw;
      case 228:
        return EControllerActionOrigin.switchProGyroRoll;
      case 229:
        return EControllerActionOrigin.switchRightGyroMove;
      case 230:
        return EControllerActionOrigin.switchRightGyroPitch;
      case 231:
        return EControllerActionOrigin.switchRightGyroYaw;
      case 232:
        return EControllerActionOrigin.switchRightGyroRoll;
      case 233:
        return EControllerActionOrigin.switchLeftGyroMove;
      case 234:
        return EControllerActionOrigin.switchLeftGyroPitch;
      case 235:
        return EControllerActionOrigin.switchLeftGyroYaw;
      case 236:
        return EControllerActionOrigin.switchLeftGyroRoll;
      case 237:
        return EControllerActionOrigin.switchLeftGripLower;
      case 238:
        return EControllerActionOrigin.switchLeftGripUpper;
      case 239:
        return EControllerActionOrigin.switchRightGripLower;
      case 240:
        return EControllerActionOrigin.switchRightGripUpper;
      case 241:
        return EControllerActionOrigin.ps4DPadMove;
      case 242:
        return EControllerActionOrigin.xBoxOneDPadMove;
      case 243:
        return EControllerActionOrigin.xBox360DPadMove;
      case 244:
        return EControllerActionOrigin.switchDPadMove;
      case 245:
        return EControllerActionOrigin.ps5X;
      case 246:
        return EControllerActionOrigin.ps5Circle;
      case 247:
        return EControllerActionOrigin.ps5Triangle;
      case 248:
        return EControllerActionOrigin.ps5Square;
      case 249:
        return EControllerActionOrigin.ps5LeftBumper;
      case 250:
        return EControllerActionOrigin.ps5RightBumper;
      case 251:
        return EControllerActionOrigin.ps5Option;
      case 252:
        return EControllerActionOrigin.ps5Create;
      case 253:
        return EControllerActionOrigin.ps5Mute;
      case 254:
        return EControllerActionOrigin.ps5LeftPadTouch;
      case 255:
        return EControllerActionOrigin.ps5LeftPadSwipe;
      case 256:
        return EControllerActionOrigin.ps5LeftPadClick;
      case 257:
        return EControllerActionOrigin.ps5LeftPadDPadNorth;
      case 258:
        return EControllerActionOrigin.ps5LeftPadDPadSouth;
      case 259:
        return EControllerActionOrigin.ps5LeftPadDPadWest;
      case 260:
        return EControllerActionOrigin.ps5LeftPadDPadEast;
      case 261:
        return EControllerActionOrigin.ps5RightPadTouch;
      case 262:
        return EControllerActionOrigin.ps5RightPadSwipe;
      case 263:
        return EControllerActionOrigin.ps5RightPadClick;
      case 264:
        return EControllerActionOrigin.ps5RightPadDPadNorth;
      case 265:
        return EControllerActionOrigin.ps5RightPadDPadSouth;
      case 266:
        return EControllerActionOrigin.ps5RightPadDPadWest;
      case 267:
        return EControllerActionOrigin.ps5RightPadDPadEast;
      case 268:
        return EControllerActionOrigin.ps5CenterPadTouch;
      case 269:
        return EControllerActionOrigin.ps5CenterPadSwipe;
      case 270:
        return EControllerActionOrigin.ps5CenterPadClick;
      case 271:
        return EControllerActionOrigin.ps5CenterPadDPadNorth;
      case 272:
        return EControllerActionOrigin.ps5CenterPadDPadSouth;
      case 273:
        return EControllerActionOrigin.ps5CenterPadDPadWest;
      case 274:
        return EControllerActionOrigin.ps5CenterPadDPadEast;
      case 275:
        return EControllerActionOrigin.ps5LeftTriggerPull;
      case 276:
        return EControllerActionOrigin.ps5LeftTriggerClick;
      case 277:
        return EControllerActionOrigin.ps5RightTriggerPull;
      case 278:
        return EControllerActionOrigin.ps5RightTriggerClick;
      case 279:
        return EControllerActionOrigin.ps5LeftStickMove;
      case 280:
        return EControllerActionOrigin.ps5LeftStickClick;
      case 281:
        return EControllerActionOrigin.ps5LeftStickDPadNorth;
      case 282:
        return EControllerActionOrigin.ps5LeftStickDPadSouth;
      case 283:
        return EControllerActionOrigin.ps5LeftStickDPadWest;
      case 284:
        return EControllerActionOrigin.ps5LeftStickDPadEast;
      case 285:
        return EControllerActionOrigin.ps5RightStickMove;
      case 286:
        return EControllerActionOrigin.ps5RightStickClick;
      case 287:
        return EControllerActionOrigin.ps5RightStickDPadNorth;
      case 288:
        return EControllerActionOrigin.ps5RightStickDPadSouth;
      case 289:
        return EControllerActionOrigin.ps5RightStickDPadWest;
      case 290:
        return EControllerActionOrigin.ps5RightStickDPadEast;
      case 291:
        return EControllerActionOrigin.ps5DPadMove;
      case 292:
        return EControllerActionOrigin.ps5DPadNorth;
      case 293:
        return EControllerActionOrigin.ps5DPadSouth;
      case 294:
        return EControllerActionOrigin.ps5DPadWest;
      case 295:
        return EControllerActionOrigin.ps5DPadEast;
      case 296:
        return EControllerActionOrigin.ps5GyroMove;
      case 297:
        return EControllerActionOrigin.ps5GyroPitch;
      case 298:
        return EControllerActionOrigin.ps5GyroYaw;
      case 299:
        return EControllerActionOrigin.ps5GyroRoll;
      case 300:
        return EControllerActionOrigin.xBoxOneLeftGripLower;
      case 301:
        return EControllerActionOrigin.xBoxOneLeftGripUpper;
      case 302:
        return EControllerActionOrigin.xBoxOneRightGripLower;
      case 303:
        return EControllerActionOrigin.xBoxOneRightGripUpper;
      case 304:
        return EControllerActionOrigin.xBoxOneShare;
      case 305:
        return EControllerActionOrigin.steamDeckA;
      case 306:
        return EControllerActionOrigin.steamDeckB;
      case 307:
        return EControllerActionOrigin.steamDeckX;
      case 308:
        return EControllerActionOrigin.steamDeckY;
      case 309:
        return EControllerActionOrigin.steamDeckL1;
      case 310:
        return EControllerActionOrigin.steamDeckR1;
      case 311:
        return EControllerActionOrigin.steamDeckMenu;
      case 312:
        return EControllerActionOrigin.steamDeckView;
      case 313:
        return EControllerActionOrigin.steamDeckLeftPadTouch;
      case 314:
        return EControllerActionOrigin.steamDeckLeftPadSwipe;
      case 315:
        return EControllerActionOrigin.steamDeckLeftPadClick;
      case 316:
        return EControllerActionOrigin.steamDeckLeftPadDPadNorth;
      case 317:
        return EControllerActionOrigin.steamDeckLeftPadDPadSouth;
      case 318:
        return EControllerActionOrigin.steamDeckLeftPadDPadWest;
      case 319:
        return EControllerActionOrigin.steamDeckLeftPadDPadEast;
      case 320:
        return EControllerActionOrigin.steamDeckRightPadTouch;
      case 321:
        return EControllerActionOrigin.steamDeckRightPadSwipe;
      case 322:
        return EControllerActionOrigin.steamDeckRightPadClick;
      case 323:
        return EControllerActionOrigin.steamDeckRightPadDPadNorth;
      case 324:
        return EControllerActionOrigin.steamDeckRightPadDPadSouth;
      case 325:
        return EControllerActionOrigin.steamDeckRightPadDPadWest;
      case 326:
        return EControllerActionOrigin.steamDeckRightPadDPadEast;
      case 327:
        return EControllerActionOrigin.steamDeckL2SoftPull;
      case 328:
        return EControllerActionOrigin.steamDeckL2;
      case 329:
        return EControllerActionOrigin.steamDeckR2SoftPull;
      case 330:
        return EControllerActionOrigin.steamDeckR2;
      case 331:
        return EControllerActionOrigin.steamDeckLeftStickMove;
      case 332:
        return EControllerActionOrigin.steamDeckL3;
      case 333:
        return EControllerActionOrigin.steamDeckLeftStickDPadNorth;
      case 334:
        return EControllerActionOrigin.steamDeckLeftStickDPadSouth;
      case 335:
        return EControllerActionOrigin.steamDeckLeftStickDPadWest;
      case 336:
        return EControllerActionOrigin.steamDeckLeftStickDPadEast;
      case 337:
        return EControllerActionOrigin.steamDeckLeftStickTouch;
      case 338:
        return EControllerActionOrigin.steamDeckRightStickMove;
      case 339:
        return EControllerActionOrigin.steamDeckR3;
      case 340:
        return EControllerActionOrigin.steamDeckRightStickDPadNorth;
      case 341:
        return EControllerActionOrigin.steamDeckRightStickDPadSouth;
      case 342:
        return EControllerActionOrigin.steamDeckRightStickDPadWest;
      case 343:
        return EControllerActionOrigin.steamDeckRightStickDPadEast;
      case 344:
        return EControllerActionOrigin.steamDeckRightStickTouch;
      case 345:
        return EControllerActionOrigin.steamDeckL4;
      case 346:
        return EControllerActionOrigin.steamDeckR4;
      case 347:
        return EControllerActionOrigin.steamDeckL5;
      case 348:
        return EControllerActionOrigin.steamDeckR5;
      case 349:
        return EControllerActionOrigin.steamDeckDPadMove;
      case 350:
        return EControllerActionOrigin.steamDeckDPadNorth;
      case 351:
        return EControllerActionOrigin.steamDeckDPadSouth;
      case 352:
        return EControllerActionOrigin.steamDeckDPadWest;
      case 353:
        return EControllerActionOrigin.steamDeckDPadEast;
      case 354:
        return EControllerActionOrigin.steamDeckGyroMove;
      case 355:
        return EControllerActionOrigin.steamDeckGyroPitch;
      case 356:
        return EControllerActionOrigin.steamDeckGyroYaw;
      case 357:
        return EControllerActionOrigin.steamDeckGyroRoll;
      case 358:
        return EControllerActionOrigin.steamDeckReserved1;
      case 359:
        return EControllerActionOrigin.steamDeckReserved2;
      case 360:
        return EControllerActionOrigin.steamDeckReserved3;
      case 361:
        return EControllerActionOrigin.steamDeckReserved4;
      case 362:
        return EControllerActionOrigin.steamDeckReserved5;
      case 363:
        return EControllerActionOrigin.steamDeckReserved6;
      case 364:
        return EControllerActionOrigin.steamDeckReserved7;
      case 365:
        return EControllerActionOrigin.steamDeckReserved8;
      case 366:
        return EControllerActionOrigin.steamDeckReserved9;
      case 367:
        return EControllerActionOrigin.steamDeckReserved10;
      case 368:
        return EControllerActionOrigin.steamDeckReserved11;
      case 369:
        return EControllerActionOrigin.steamDeckReserved12;
      case 370:
        return EControllerActionOrigin.steamDeckReserved13;
      case 371:
        return EControllerActionOrigin.steamDeckReserved14;
      case 372:
        return EControllerActionOrigin.steamDeckReserved15;
      case 373:
        return EControllerActionOrigin.steamDeckReserved16;
      case 374:
        return EControllerActionOrigin.steamDeckReserved17;
      case 375:
        return EControllerActionOrigin.steamDeckReserved18;
      case 376:
        return EControllerActionOrigin.steamDeckReserved19;
      case 377:
        return EControllerActionOrigin.steamDeckReserved20;
      case 378:
        return EControllerActionOrigin.switchJoyConButtonN;
      case 379:
        return EControllerActionOrigin.switchJoyConButtonE;
      case 380:
        return EControllerActionOrigin.switchJoyConButtonS;
      case 381:
        return EControllerActionOrigin.switchJoyConButtonW;
      case 382:
        return EControllerActionOrigin.ps5LeftGrip;
      case 383:
        return EControllerActionOrigin.ps5RightGrip;
      case 384:
        return EControllerActionOrigin.ps5LeftFn;
      case 385:
        return EControllerActionOrigin.ps5RightFn;
      case 386:
        return EControllerActionOrigin.horipadM1;
      case 387:
        return EControllerActionOrigin.horipadM2;
      case 388:
        return EControllerActionOrigin.horipadL4;
      case 389:
        return EControllerActionOrigin.horipadR4;
      case 390:
        return EControllerActionOrigin.lenovoLegionGoA;
      case 391:
        return EControllerActionOrigin.lenovoLegionGoB;
      case 392:
        return EControllerActionOrigin.lenovoLegionGoX;
      case 393:
        return EControllerActionOrigin.lenovoLegionGoY;
      case 394:
        return EControllerActionOrigin.lenovoLegionGoLB;
      case 395:
        return EControllerActionOrigin.lenovoLegionGoRB;
      case 396:
        return EControllerActionOrigin.lenovoLegionGoMenu;
      case 397:
        return EControllerActionOrigin.lenovoLegionGoView;
      case 398:
        return EControllerActionOrigin.lenovoLegionGoLeftPadTouch;
      case 399:
        return EControllerActionOrigin.lenovoLegionGoLeftPadSwipe;
      case 400:
        return EControllerActionOrigin.lenovoLegionGoLeftPadClick;
      case 401:
        return EControllerActionOrigin.lenovoLegionGoLeftPadDPadNorth;
      case 402:
        return EControllerActionOrigin.lenovoLegionGoLeftPadDPadSouth;
      case 403:
        return EControllerActionOrigin.lenovoLegionGoLeftPadDPadWest;
      case 404:
        return EControllerActionOrigin.lenovoLegionGoLeftPadDPadEast;
      case 405:
        return EControllerActionOrigin.lenovoLegionGoRightPadTouch;
      case 406:
        return EControllerActionOrigin.lenovoLegionGoRightPadSwipe;
      case 407:
        return EControllerActionOrigin.lenovoLegionGoRightPadClick;
      case 408:
        return EControllerActionOrigin.lenovoLegionGoRightPadDPadNorth;
      case 409:
        return EControllerActionOrigin.lenovoLegionGoRightPadDPadSouth;
      case 410:
        return EControllerActionOrigin.lenovoLegionGoRightPadDPadWest;
      case 411:
        return EControllerActionOrigin.lenovoLegionGoRightPadDPadEast;
      case 412:
        return EControllerActionOrigin.lenovoLegionGoLTSoftPull;
      case 413:
        return EControllerActionOrigin.lenovoLegionGoLT;
      case 414:
        return EControllerActionOrigin.lenovoLegionGoRTSoftPull;
      case 415:
        return EControllerActionOrigin.lenovoLegionGoRT;
      case 416:
        return EControllerActionOrigin.lenovoLegionGoLeftStickMove;
      case 417:
        return EControllerActionOrigin.lenovoLegionGoLS;
      case 418:
        return EControllerActionOrigin.lenovoLegionGoLeftStickDPadNorth;
      case 419:
        return EControllerActionOrigin.lenovoLegionGoLeftStickDPadSouth;
      case 420:
        return EControllerActionOrigin.lenovoLegionGoLeftStickDPadWest;
      case 421:
        return EControllerActionOrigin.lenovoLegionGoLeftStickDPadEast;
      case 422:
        return EControllerActionOrigin.lenovoLegionGoRightStickMove;
      case 423:
        return EControllerActionOrigin.lenovoLegionGoRS;
      case 424:
        return EControllerActionOrigin.lenovoLegionGoRightStickDPadNorth;
      case 425:
        return EControllerActionOrigin.lenovoLegionGoRightStickDPadSouth;
      case 426:
        return EControllerActionOrigin.lenovoLegionGoRightStickDPadWest;
      case 427:
        return EControllerActionOrigin.lenovoLegionGoRightStickDPadEast;
      case 428:
        return EControllerActionOrigin.lenovoLegionGoY1;
      case 429:
        return EControllerActionOrigin.lenovoLegionGoY2;
      case 430:
        return EControllerActionOrigin.lenovoLegionGoDPadMove;
      case 431:
        return EControllerActionOrigin.lenovoLegionGoDPadNorth;
      case 432:
        return EControllerActionOrigin.lenovoLegionGoDPadSouth;
      case 433:
        return EControllerActionOrigin.lenovoLegionGoDPadWest;
      case 434:
        return EControllerActionOrigin.lenovoLegionGoDPadEast;
      case 435:
        return EControllerActionOrigin.lenovoLegionGoGyroMove;
      case 436:
        return EControllerActionOrigin.lenovoLegionGoGyroPitch;
      case 437:
        return EControllerActionOrigin.lenovoLegionGoGyroYaw;
      case 438:
        return EControllerActionOrigin.lenovoLegionGoGyroRoll;
      case 439:
        return EControllerActionOrigin.lenovoLegionGoReserved1;
      case 440:
        return EControllerActionOrigin.lenovoLegionGoReserved2;
      case 441:
        return EControllerActionOrigin.lenovoLegionGoReserved3;
      case 442:
        return EControllerActionOrigin.lenovoLegionGoReserved4;
      case 443:
        return EControllerActionOrigin.lenovoLegionGoReserved5;
      case 444:
        return EControllerActionOrigin.lenovoLegionGoReserved6;
      case 445:
        return EControllerActionOrigin.lenovoLegionGoReserved7;
      case 446:
        return EControllerActionOrigin.lenovoLegionGoReserved8;
      case 447:
        return EControllerActionOrigin.lenovoLegionGoReserved9;
      case 448:
        return EControllerActionOrigin.lenovoLegionGoReserved10;
      case 449:
        return EControllerActionOrigin.lenovoLegionGoReserved11;
      case 450:
        return EControllerActionOrigin.lenovoLegionGoReserved12;
      case 451:
        return EControllerActionOrigin.lenovoLegionGoReserved13;
      case 452:
        return EControllerActionOrigin.lenovoLegionGoReserved14;
      case 453:
        return EControllerActionOrigin.lenovoLegionGoReserved15;
      case 454:
        return EControllerActionOrigin.lenovoLegionGoReserved16;
      case 455:
        return EControllerActionOrigin.lenovoLegionGoReserved17;
      case 456:
        return EControllerActionOrigin.lenovoLegionGoReserved18;
      case 457:
        return EControllerActionOrigin.lenovoLegionGoReserved19;
      case 458:
        return EControllerActionOrigin.lenovoLegionGoReserved20;
      case 459:
        return EControllerActionOrigin.genericL4;
      case 460:
        return EControllerActionOrigin.genericR4;
      case 461:
        return EControllerActionOrigin.genericL5;
      case 462:
        return EControllerActionOrigin.genericR5;
      case 463:
        return EControllerActionOrigin.genericPL;
      case 464:
        return EControllerActionOrigin.genericPR;
      case 465:
        return EControllerActionOrigin.genericC;
      case 466:
        return EControllerActionOrigin.genericZ;
      case 467:
        return EControllerActionOrigin.genericMISC1;
      case 468:
        return EControllerActionOrigin.genericMISC2;
      case 469:
        return EControllerActionOrigin.genericMISC3;
      case 470:
        return EControllerActionOrigin.genericMISC4;
      case 471:
        return EControllerActionOrigin.genericMISC5;
      case 472:
        return EControllerActionOrigin.genericMISC6;
      case 473:
        return EControllerActionOrigin.genericMISC7;
      case 474:
        return EControllerActionOrigin.genericMISC8;
      case 475:
        return EControllerActionOrigin.switch2A;
      case 476:
        return EControllerActionOrigin.switch2B;
      case 477:
        return EControllerActionOrigin.switch2X;
      case 478:
        return EControllerActionOrigin.switch2Y;
      case 479:
        return EControllerActionOrigin.switch2LeftBumper;
      case 480:
        return EControllerActionOrigin.switch2RightBumper;
      case 481:
        return EControllerActionOrigin.switch2Plus;
      case 482:
        return EControllerActionOrigin.switch2Minus;
      case 483:
        return EControllerActionOrigin.switch2Capture;
      case 484:
        return EControllerActionOrigin.switch2LeftTriggerPull;
      case 485:
        return EControllerActionOrigin.switch2LeftTriggerClick;
      case 486:
        return EControllerActionOrigin.switch2RightTriggerPull;
      case 487:
        return EControllerActionOrigin.switch2RightTriggerClick;
      case 488:
        return EControllerActionOrigin.switch2LeftStickMove;
      case 489:
        return EControllerActionOrigin.switch2LeftStickClick;
      case 490:
        return EControllerActionOrigin.switch2LeftStickDPadNorth;
      case 491:
        return EControllerActionOrigin.switch2LeftStickDPadSouth;
      case 492:
        return EControllerActionOrigin.switch2LeftStickDPadWest;
      case 493:
        return EControllerActionOrigin.switch2LeftStickDPadEast;
      case 494:
        return EControllerActionOrigin.switch2RightStickMove;
      case 495:
        return EControllerActionOrigin.switch2RightStickClick;
      case 496:
        return EControllerActionOrigin.switch2RightStickDPadNorth;
      case 497:
        return EControllerActionOrigin.switch2RightStickDPadSouth;
      case 498:
        return EControllerActionOrigin.switch2RightStickDPadWest;
      case 499:
        return EControllerActionOrigin.switch2RightStickDPadEast;
      case 500:
        return EControllerActionOrigin.switch2DPadMove;
      case 501:
        return EControllerActionOrigin.switch2DPadNorth;
      case 502:
        return EControllerActionOrigin.switch2DPadSouth;
      case 503:
        return EControllerActionOrigin.switch2DPadWest;
      case 504:
        return EControllerActionOrigin.switch2DPadEast;
      case 505:
        return EControllerActionOrigin.switch2ProGyroMove;
      case 506:
        return EControllerActionOrigin.switch2ProGyroPitch;
      case 507:
        return EControllerActionOrigin.switch2ProGyroYaw;
      case 508:
        return EControllerActionOrigin.switch2ProGyroRoll;
      case 509:
        return EControllerActionOrigin.switch2GL;
      case 510:
        return EControllerActionOrigin.switch2GR;
      case 511:
        return EControllerActionOrigin.switch2C;
      case 512:
        return EControllerActionOrigin.switch2Reserved1;
      case 513:
        return EControllerActionOrigin.switch2Reserved2;
      case 514:
        return EControllerActionOrigin.switch2Reserved3;
      case 515:
        return EControllerActionOrigin.switch2Reserved4;
      case 516:
        return EControllerActionOrigin.switch2Reserved5;
      case 517:
        return EControllerActionOrigin.switch2Reserved6;
      case 518:
        return EControllerActionOrigin.switch2Reserved7;
      case 519:
        return EControllerActionOrigin.switch2Reserved8;
      case 520:
        return EControllerActionOrigin.switch2Reserved9;
      case 521:
        return EControllerActionOrigin.switch2Reserved10;
      case 522:
        return EControllerActionOrigin.steamController2026A;
      case 523:
        return EControllerActionOrigin.steamController2026B;
      case 524:
        return EControllerActionOrigin.steamController2026X;
      case 525:
        return EControllerActionOrigin.steamController2026Y;
      case 526:
        return EControllerActionOrigin.steamController2026L1;
      case 527:
        return EControllerActionOrigin.steamController2026R1;
      case 528:
        return EControllerActionOrigin.steamController2026Menu;
      case 529:
        return EControllerActionOrigin.steamController2026View;
      case 530:
        return EControllerActionOrigin.steamController2026LeftPadTouch;
      case 531:
        return EControllerActionOrigin.steamController2026LeftPadSwipe;
      case 532:
        return EControllerActionOrigin.steamController2026LeftPadClick;
      case 533:
        return EControllerActionOrigin.steamController2026LeftPadDPadNorth;
      case 534:
        return EControllerActionOrigin.steamController2026LeftPadDPadSouth;
      case 535:
        return EControllerActionOrigin.steamController2026LeftPadDPadWest;
      case 536:
        return EControllerActionOrigin.steamController2026LeftPadDPadEast;
      case 537:
        return EControllerActionOrigin.steamController2026RightPadTouch;
      case 538:
        return EControllerActionOrigin.steamController2026RightPadSwipe;
      case 539:
        return EControllerActionOrigin.steamController2026RightPadClick;
      case 540:
        return EControllerActionOrigin.steamController2026RightPadDPadNorth;
      case 541:
        return EControllerActionOrigin.steamController2026RightPadDPadSouth;
      case 542:
        return EControllerActionOrigin.steamController2026RightPadDPadWest;
      case 543:
        return EControllerActionOrigin.steamController2026RightPadDPadEast;
      case 544:
        return EControllerActionOrigin.steamController2026L2SoftPull;
      case 545:
        return EControllerActionOrigin.steamController2026L2;
      case 546:
        return EControllerActionOrigin.steamController2026R2SoftPull;
      case 547:
        return EControllerActionOrigin.steamController2026R2;
      case 548:
        return EControllerActionOrigin.steamController2026LeftStickMove;
      case 549:
        return EControllerActionOrigin.steamController2026L3;
      case 550:
        return EControllerActionOrigin.steamController2026LeftStickDPadNorth;
      case 551:
        return EControllerActionOrigin.steamController2026LeftStickDPadSouth;
      case 552:
        return EControllerActionOrigin.steamController2026LeftStickDPadWest;
      case 553:
        return EControllerActionOrigin.steamController2026LeftStickDPadEast;
      case 554:
        return EControllerActionOrigin.steamController2026LeftStickTouch;
      case 555:
        return EControllerActionOrigin.steamController2026RightStickMove;
      case 556:
        return EControllerActionOrigin.steamController2026R3;
      case 557:
        return EControllerActionOrigin.steamController2026RightStickDPadNorth;
      case 558:
        return EControllerActionOrigin.steamController2026RightStickDPadSouth;
      case 559:
        return EControllerActionOrigin.steamController2026RightStickDPadWest;
      case 560:
        return EControllerActionOrigin.steamController2026RightStickDPadEast;
      case 561:
        return EControllerActionOrigin.steamController2026RightStickTouch;
      case 562:
        return EControllerActionOrigin.steamController2026L4;
      case 563:
        return EControllerActionOrigin.steamController2026R4;
      case 564:
        return EControllerActionOrigin.steamController2026L5;
      case 565:
        return EControllerActionOrigin.steamController2026R5;
      case 566:
        return EControllerActionOrigin.steamController2026DPadMove;
      case 567:
        return EControllerActionOrigin.steamController2026DPadNorth;
      case 568:
        return EControllerActionOrigin.steamController2026DPadSouth;
      case 569:
        return EControllerActionOrigin.steamController2026DPadWest;
      case 570:
        return EControllerActionOrigin.steamController2026DPadEast;
      case 571:
        return EControllerActionOrigin.steamController2026GyroMove;
      case 572:
        return EControllerActionOrigin.steamController2026GyroPitch;
      case 573:
        return EControllerActionOrigin.steamController2026GyroYaw;
      case 574:
        return EControllerActionOrigin.steamController2026GyroRoll;
      case 575:
        return EControllerActionOrigin.steamController2026LGrip;
      case 576:
        return EControllerActionOrigin.steamController2026RGrip;
      case 577:
        return EControllerActionOrigin.steamController2026Reserved1;
      case 578:
        return EControllerActionOrigin.steamController2026Reserved2;
      case 579:
        return EControllerActionOrigin.steamController2026Reserved3;
      case 580:
        return EControllerActionOrigin.steamController2026Reserved4;
      case 581:
        return EControllerActionOrigin.steamController2026Reserved5;
      case 582:
        return EControllerActionOrigin.steamController2026Reserved6;
      case 583:
        return EControllerActionOrigin.steamController2026Reserved7;
      case 584:
        return EControllerActionOrigin.steamController2026Reserved8;
      case 585:
        return EControllerActionOrigin.steamController2026Reserved9;
      case 586:
        return EControllerActionOrigin.steamController2026Reserved10;
      case 587:
        return EControllerActionOrigin.steamController2026Reserved11;
      case 588:
        return EControllerActionOrigin.steamController2026Reserved12;
      case 589:
        return EControllerActionOrigin.steamController2026Reserved13;
      case 590:
        return EControllerActionOrigin.steamController2026Reserved14;
      case 591:
        return EControllerActionOrigin.steamController2026Reserved15;
      case 592:
        return EControllerActionOrigin.steamController2026Reserved16;
      case 593:
        return EControllerActionOrigin.steamController2026Reserved17;
      case 594:
        return EControllerActionOrigin.steamController2026Reserved18;
      case 595:
        return EControllerActionOrigin.steamController2026Reserved19;
      case 596:
        return EControllerActionOrigin.steamController2026Reserved20;
      case 597:
        return EControllerActionOrigin.steamFrameControllerAClick;
      case 598:
        return EControllerActionOrigin.steamFrameControllerATouch;
      case 599:
        return EControllerActionOrigin.steamFrameControllerBClick;
      case 600:
        return EControllerActionOrigin.steamFrameControllerBTouch;
      case 601:
        return EControllerActionOrigin.steamFrameControllerXClick;
      case 602:
        return EControllerActionOrigin.steamFrameControllerXTouch;
      case 603:
        return EControllerActionOrigin.steamFrameControllerYClick;
      case 604:
        return EControllerActionOrigin.steamFrameControllerYTouch;
      case 605:
        return EControllerActionOrigin.steamFrameControllerLeftTriggerPull;
      case 606:
        return EControllerActionOrigin.steamFrameControllerLeftTriggerClick;
      case 607:
        return EControllerActionOrigin.steamFrameControllerLeftTriggerTouch;
      case 608:
        return EControllerActionOrigin.steamFrameControllerRightTriggerPull;
      case 609:
        return EControllerActionOrigin.steamFrameControllerRightTriggerClick;
      case 610:
        return EControllerActionOrigin.steamFrameControllerRightTriggerTouch;
      case 611:
        return EControllerActionOrigin.steamFrameControllerMenuClick;
      case 612:
        return EControllerActionOrigin.steamFrameControllerMenuTouch;
      case 613:
        return EControllerActionOrigin.steamFrameControllerViewClick;
      case 614:
        return EControllerActionOrigin.steamFrameControllerViewTouch;
      case 615:
        return EControllerActionOrigin.steamFrameControllerLeftBumperClick;
      case 616:
        return EControllerActionOrigin.steamFrameControllerLeftBumperTouch;
      case 617:
        return EControllerActionOrigin.steamFrameControllerRightBumperClick;
      case 618:
        return EControllerActionOrigin.steamFrameControllerRightBumperTouch;
      case 619:
        return EControllerActionOrigin.steamFrameControllerLeftStickMove;
      case 620:
        return EControllerActionOrigin.steamFrameControllerLeftStickClick;
      case 621:
        return EControllerActionOrigin.steamFrameControllerLeftStickDPadNorth;
      case 622:
        return EControllerActionOrigin.steamFrameControllerLeftStickDPadSouth;
      case 623:
        return EControllerActionOrigin.steamFrameControllerLeftStickDPadWest;
      case 624:
        return EControllerActionOrigin.steamFrameControllerLeftStickDPadEast;
      case 625:
        return EControllerActionOrigin.steamFrameControllerLeftStickTouch;
      case 626:
        return EControllerActionOrigin.steamFrameControllerRightStickMove;
      case 627:
        return EControllerActionOrigin.steamFrameControllerRightStickClick;
      case 628:
        return EControllerActionOrigin.steamFrameControllerRightStickDPadNorth;
      case 629:
        return EControllerActionOrigin.steamFrameControllerRightStickDPadSouth;
      case 630:
        return EControllerActionOrigin.steamFrameControllerRightStickDPadWest;
      case 631:
        return EControllerActionOrigin.steamFrameControllerRightStickDPadEast;
      case 632:
        return EControllerActionOrigin.steamFrameControllerRightStickTouch;
      case 633:
        return EControllerActionOrigin.steamFrameControllerDPadMove;
      case 634:
        return EControllerActionOrigin.steamFrameControllerDPadNorth;
      case 635:
        return EControllerActionOrigin.steamFrameControllerDPadSouth;
      case 636:
        return EControllerActionOrigin.steamFrameControllerDPadWest;
      case 637:
        return EControllerActionOrigin.steamFrameControllerDPadEast;
      case 638:
        return EControllerActionOrigin.steamFrameControllerDPadTouch;
      case 639:
        return EControllerActionOrigin.steamFrameControllerLeftGyroMove;
      case 640:
        return EControllerActionOrigin.steamFrameControllerLeftGyroPitch;
      case 641:
        return EControllerActionOrigin.steamFrameControllerLeftGyroYaw;
      case 642:
        return EControllerActionOrigin.steamFrameControllerLeftGyroRoll;
      case 643:
        return EControllerActionOrigin.steamFrameControllerRightGyroMove;
      case 644:
        return EControllerActionOrigin.steamFrameControllerRightGyroPitch;
      case 645:
        return EControllerActionOrigin.steamFrameControllerRightGyroYaw;
      case 646:
        return EControllerActionOrigin.steamFrameControllerRightGyroRoll;
      case 647:
        return EControllerActionOrigin.steamFrameControllerLeftGripPull;
      case 648:
        return EControllerActionOrigin.steamFrameControllerLeftGripClick;
      case 649:
        return EControllerActionOrigin.steamFrameControllerLeftGripTouch;
      case 650:
        return EControllerActionOrigin.steamFrameControllerRightGripPull;
      case 651:
        return EControllerActionOrigin.steamFrameControllerRightGripClick;
      case 652:
        return EControllerActionOrigin.steamFrameControllerRightGripTouch;
      case 653:
        return EControllerActionOrigin.steamFrameControllerLeftThumbrestTouch;
      case 654:
        return EControllerActionOrigin.steamFrameControllerRightThumbrestTouch;
      case 655:
        return EControllerActionOrigin.steamFrameControllerReserved1;
      case 656:
        return EControllerActionOrigin.steamFrameControllerReserved2;
      case 657:
        return EControllerActionOrigin.steamFrameControllerReserved3;
      case 658:
        return EControllerActionOrigin.steamFrameControllerReserved4;
      case 659:
        return EControllerActionOrigin.steamFrameControllerReserved5;
      case 660:
        return EControllerActionOrigin.steamFrameControllerReserved6;
      case 661:
        return EControllerActionOrigin.steamFrameControllerReserved7;
      case 662:
        return EControllerActionOrigin.steamFrameControllerReserved8;
      case 663:
        return EControllerActionOrigin.steamFrameControllerReserved9;
      case 664:
        return EControllerActionOrigin.steamFrameControllerReserved10;
      case 665:
        return EControllerActionOrigin.steamFrameControllerReserved11;
      case 666:
        return EControllerActionOrigin.steamFrameControllerReserved12;
      case 667:
        return EControllerActionOrigin.steamFrameControllerReserved13;
      case 668:
        return EControllerActionOrigin.steamFrameControllerReserved14;
      case 669:
        return EControllerActionOrigin.steamFrameControllerReserved15;
      case 670:
        return EControllerActionOrigin.steamFrameControllerReserved16;
      case 671:
        return EControllerActionOrigin.steamFrameControllerReserved17;
      case 672:
        return EControllerActionOrigin.steamFrameControllerReserved18;
      case 673:
        return EControllerActionOrigin.steamFrameControllerReserved19;
      case 674:
        return EControllerActionOrigin.steamFrameControllerReserved20;
      case 675:
        return EControllerActionOrigin.count;
      case 32767:
        return EControllerActionOrigin.maximumPossibleValue;
      default:
        throw UnknownEnumValueException(
            "Unknown value for 'EControllerActionOrigin'. The value was: '$value'");
    }
  }
}
