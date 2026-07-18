BEGIN;

DELETE FROM article_keyword;

INSERT INTO article_keyword (articleid, keywordid) VALUES

-- artikel_1
-- Perl, Dancer2, SQLite, Docker, OAuth2, Open Source
(1, 40),
(1, 11),
(1, 47),
(1, 13),
(1, 36),
(1, 38),

-- eerste_indruk
-- UX, Softwareontwikkeling, Troubleshooting
(5, 52),
(5, 45),
(5, 51),

-- oauth2_authenticatie_met_curl
-- OAuth2, Microsoft Graph, Perl, API, Automatisering
(6, 36),
(6, 33),
(6, 40),
(6, 1),
(6, 5),

-- desem_drogen
-- Zuurdesem, Desem, Brood bakken
(8, 53),
(8, 12),
(8, 7),

-- editor_en_login
-- Markdown, OAuth2, Google OAuth, Perl, Dancer2, UX
(9, 28),
(9, 36),
(9, 20),
(9, 40),
(9, 11),
(9, 52),

-- de_looks_zijn_veranderd
-- UX, Softwareontwikkeling, Troubleshooting
(11, 52),
(11, 45),
(11, 51),

-- desem_voorbereiden_zo_maak_je_je_zuurdesem_starter_weer_actief
-- Zuurdesem, Desem, Brood bakken
(12, 53),
(12, 12),
(12, 7),

-- can_of_worms
-- Softwareontwikkeling, Scope Creep, Architectuur
(13, 45),
(13, 43),
(13, 4),

-- ptl_van_het_een_komt_het_ander
-- ESP32, ArduCam, Python, Flask, Firmware, Time-lapse, Automatisering
(14, 15),
(14, 2),
(14, 42),
(14, 18),
(14, 17),
(14, 50),
(14, 5),

-- ptl_arducam_voedingproblemen_en_esp8266_beperkingen
-- ESP8266, ESP32, ArduCam, Hardware, SPI, Troubleshooting, Firmware
(15, 16),
(15, 15),
(15, 2),
(15, 22),
(15, 46),
(15, 51),
(15, 17),

-- ptl_eindelijk_beeld_uit_de_arducam
-- ESP32, ArduCam, Flask, Firmware, Troubleshooting, API
(16, 15),
(16, 2),
(16, 18),
(16, 17),
(16, 51),
(16, 1),

-- ptl_waarom_de_juiste_hardware_ertoe_doet
-- ESP32, Hardware, Microcontrollers, Time-lapse, ArduCam
(17, 15),
(17, 22),
(17, 31),
(17, 50),
(17, 2),

-- waarom_ik_als_cloud_first_beheerder_opnieuw_ben_gaan_bouwen
-- Cloudarchitectuur, Kubernetes, Containers, Identity, Governance, Architectuur
(18, 9),
(18, 27),
(18, 10),
(18, 24),
(18, 21),
(18, 4),

-- de_cloud_als_gelaagde_omgeving
-- Cloudarchitectuur, Architectuur, Containers, Identity
(20, 9),
(20, 4),
(20, 10),
(20, 24),

-- van_cloudmodel_naar_concrete_keuzes
-- Cloudarchitectuur, Architectuur, Governance, Kubernetes, Identity
(21, 9),
(21, 4),
(21, 21),
(21, 27),
(21, 24),

-- bouwstenen_voor_een_uitlegbare_cloud
-- Cloudarchitectuur, Governance, Architectuur, Kubernetes, Containers
(22, 9),
(22, 21),
(22, 4),
(22, 27),
(22, 10),

-- omgaan_met_kubernetes_secrets_praktijk_en_valkuilen
-- Kubernetes, GitOps, Governance, Architectuur, Troubleshooting
(23, 27),
(23, 19),
(23, 21),
(23, 4),
(23, 51),

-- van_microk8s_naar_k3s_de_weg_naar_reproduceerbaarheid
-- Kubernetes, k3s, MicroK8s, ArgoCD, GitOps, Containers
(24, 27),
(24, 26),
(24, 32),
(24, 3),
(24, 19),
(24, 10),

-- semantiek_voor_observability
-- Observability, Architectuur, Monitoring, Metrics
(25, 37),
(25, 4),
(25, 35),
(25, 30),

-- hoe_ik_teams_niet_maak_en_ze_toch_ontstaan
-- EduTeams, Microsoft Graph, Microsoft Teams, HelloID, Azure Automation, Automatisering
(26, 14),
(26, 33),
(26, 34),
(26, 23),
(26, 6),
(26, 5),

-- using_microsoft_graph_from_perl
-- Microsoft Graph, Perl, OAuth2, API, EduTeams, Automatisering
(27, 33),
(27, 40),
(27, 36),
(27, 1),
(27, 14),
(27, 5),

-- van_bilbowashere_tot_json_ld
-- SEO, JSON-LD, Structured Data
(28, 44),
(28, 25),
(28, 48),

-- observability_sqlite_en_de_verkeerde_verdachte
-- Observability, Prometheus, Memcached, SQLite, Performance, Dancer2, Perl
(29, 37),
(29, 41),
(29, 29),
(29, 47),
(29, 39),
(29, 11),
(29, 40);

COMMIT;