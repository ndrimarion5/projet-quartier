

DROP TABLE IF EXISTS historique_actions CASCADE;
DROP TABLE IF EXISTS Mouvement_residuel CASCADE;
DROP TABLE IF EXISTS Evenement_vital CASCADE;
DROP TABLE IF EXISTS utilisateurs CASCADE;
DROP TABLE IF EXISTS Habitant CASCADE;
DROP TABLE IF EXISTS Menages CASCADE;

CREATE TABLE Menages (
    id_menage SERIAL PRIMARY KEY,
    adresse VARCHAR(50) NOT NULL,
    revenu INT,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    secteur VARCHAR(100),
    score_vulnerabilite DECIMAL(5,2) DEFAULT 0,
    id_chef_menage INTEGER,

    CONSTRAINT chk_menage_revenu CHECK (revenu IS NULL OR revenu >= 0),
    CONSTRAINT chk_menage_score_vulnerabilite CHECK (score_vulnerabilite IS NULL OR score_vulnerabilite BETWEEN 0 AND 100),
    CONSTRAINT chk_menage_latitude CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),
    CONSTRAINT chk_menage_longitude CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180),
    CONSTRAINT chk_menage_coordonnees_pair CHECK (
        (latitude IS NULL AND longitude IS NULL)
        OR
        (latitude IS NOT NULL AND longitude IS NOT NULL)
    )
);

CREATE TABLE Habitant (
    id_habitant SERIAL PRIMARY KEY,
    nom VARCHAR(50) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    sexe VARCHAR(50) NOT NULL,
    date_de_naissance DATE,
    profession VARCHAR(50),
    niveau_etude VARCHAR(50),
    telephone VARCHAR(20),
    statut VARCHAR(20) NOT NULL DEFAULT 'actif',
    id_menage INT,
    position_menage VARCHAR(100),
    lien_avec_chef VARCHAR(50),

    CONSTRAINT fk_habitant_menage FOREIGN KEY (id_menage) REFERENCES Menages(id_menage),
    CONSTRAINT chk_habitant_sexe CHECK (sexe IN ('Masculin', 'Féminin')),
    CONSTRAINT chk_habitant_statut CHECK (statut IN ('actif', 'decede', 'parti')),
    CONSTRAINT chk_habitant_date_naissance CHECK (date_de_naissance IS NULL OR date_de_naissance <= CURRENT_DATE),
    CONSTRAINT chk_habitant_telephone CHECK (
        telephone IS NULL
        OR telephone = ''
        OR telephone ~ '^[+0-9 ()-]{8,20}$'
    ),
    CONSTRAINT chk_lien_avec_chef CHECK (
        lien_avec_chef IS NULL OR lien_avec_chef IN (
            'Chef de ménage',
            'Épouse / Conjointe',
            'Époux / Conjoint',
            'Enfant',
            'Père / Mère',
            'Frère / Sœur',
            'Petit-fils / Petite-fille',
            'Autre parent',
            'Domestique',
            'Autre'
        )
    )
);

CREATE TABLE Evenement_vital (
    id_evenement SERIAL PRIMARY KEY,
    type_evenement VARCHAR(50) NOT NULL,
    date_evenement DATE NOT NULL,
    description VARCHAR(200),
    id_habitant INT NOT NULL,

    CONSTRAINT fk_evenement_habitant FOREIGN KEY (id_habitant) REFERENCES Habitant(id_habitant),
    CONSTRAINT chk_evenement_type CHECK (type_evenement IN ('naissance', 'deces')),
    CONSTRAINT chk_evenement_date CHECK (date_evenement <= CURRENT_DATE)
);

CREATE TABLE Mouvement_residuel (
    id_mouvement SERIAL PRIMARY KEY,
    type_mouvement VARCHAR(50) NOT NULL,
    date_mouvement DATE NOT NULL,
    provenance VARCHAR(100),
    destination VARCHAR(100),
    id_habitant INT NOT NULL,

    CONSTRAINT fk_mouvement_habitant FOREIGN KEY (id_habitant) REFERENCES Habitant(id_habitant),
    CONSTRAINT chk_mouvement_type CHECK (type_mouvement IN ('arrivee', 'depart', 'interne')),
    CONSTRAINT chk_mouvement_date CHECK (date_mouvement <= CURRENT_DATE),
    CONSTRAINT chk_mouvement_provenance_destination CHECK (
        (type_mouvement = 'arrivee' AND provenance IS NOT NULL AND provenance <> '')
        OR
        (type_mouvement = 'depart' AND destination IS NOT NULL AND destination <> '')
        OR
        (type_mouvement = 'interne' AND destination IS NOT NULL AND destination <> '')
    )
);

CREATE TABLE historique_actions (
    id SERIAL PRIMARY KEY,
    utilisateur VARCHAR(50) NOT NULL,
    role VARCHAR(50) NOT NULL,
    action VARCHAR(200) NOT NULL,
    details TEXT DEFAULT '',
    date_action TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE utilisateurs (
    id_utilisateur SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL,
    label VARCHAR(100),
    email VARCHAR(100) UNIQUE NOT NULL,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_utilisateur_role CHECK (role IN ('admin', 'agent', 'responsable', 'hote')),
    CONSTRAINT chk_utilisateur_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Index techniques
CREATE INDEX idx_menage_chef ON Menages(id_chef_menage);
CREATE INDEX idx_habitant_statut ON Habitant(statut);
CREATE INDEX idx_habitant_menage ON Habitant(id_menage);
CREATE INDEX idx_habitant_nom ON Habitant(nom, prenom);
CREATE INDEX idx_evt_type_date ON Evenement_vital(type_evenement, date_evenement);
CREATE INDEX idx_evt_habitant ON Evenement_vital(id_habitant);
CREATE INDEX idx_mvt_type_date ON Mouvement_residuel(type_mouvement, date_mouvement);
CREATE INDEX idx_mvt_habitant ON Mouvement_residuel(id_habitant);
CREATE INDEX idx_hist_date ON historique_actions(date_action DESC);
CREATE INDEX idx_hist_user ON historique_actions(utilisateur);

-- Empêche deux chefs actifs dans un même ménage.
CREATE UNIQUE INDEX uq_un_chef_actif_par_menage
ON Habitant(id_menage)
WHERE lien_avec_chef = 'Chef de ménage'
  AND statut = 'actif'
  AND id_menage IS NOT NULL;

-- ATTENTION : non activé car les données fournies contiennent un doublon de téléphone : +2256555465655.
-- Après correction du doublon, tu peux activer l'index suivant :
-- CREATE UNIQUE INDEX idx_habitant_telephone_unique
-- ON Habitant(telephone)
-- WHERE telephone IS NOT NULL AND telephone <> '';

INSERT INTO Menages (id_menage, adresse, revenu, latitude, longitude, secteur, score_vulnerabilite, id_chef_menage) VALUES
(6, 'Danga Centre, Avenue principale 1', 800000, 5.35050000, -4.00150000, 'Danga Centre', 20.00, 24),
(1, 'Danga Nord, Rue des Jardins 1', 75000, 5.35210000, -4.00120000, 'Danga Nord', 25.00, NULL),
(2, 'Danga Nord, Rue des Jardins 2', 450000, 5.35240000, -4.00090000, 'Danga Nord', 35.00, NULL),
(3, 'Danga Nord, Rue des Jardins 3', 320000, 5.35270000, -4.00060000, 'Danga Nord', 45.00, NULL),
(4, 'Danga Sud, Rue des Écoles 1', 150000, 5.34890000, -4.00210000, 'Danga Sud', 55.00, NULL),
(5, 'Danga Sud, Rue des Écoles 2', 120000, 5.34860000, -4.00250000, 'Danga Sud', 60.00, NULL),
(7, 'Danga Centre, Avenue principale 2', 270000, 5.35080000, -4.00110000, 'Danga Centre', 30.00, NULL),
(8, 'Danga Résidentiel, Rue des Palmiers 1', 200000, 5.35120000, -3.99990000, 'Danga Résidentiel', 15.00, NULL),
(9, 'Danga Résidentiel, Rue des Palmiers 2', 130000, 5.35160000, -3.99950000, 'Danga Résidentiel', 18.00, NULL),
(10, 'Danga Extension, Rue des Manguiers 1', 90000, 5.34970000, -3.99890000, 'Danga Extension', 70.00, 31),
(11, 'Danga Extension, Rue des Manguiers 2', 210000, 5.34930000, -3.99850000, 'Danga Extension', 75.00, NULL),
(12, 'Danga Nord, Rue des Jardins 4', 500000, 5.35300000, -4.00030000, 'Danga Nord', 40.00, NULL),
(13, 'Danga Nord, Rue des Jardins 5', 350000, 5.35330000, -4.00000000, 'Danga Nord', 42.00, NULL),
(14, 'Danga Sud, Rue des Écoles 3', 160000, 5.34830000, -4.00280000, 'Danga Sud', 62.00, NULL),
(15, 'Danga Sud, Rue des Écoles 4', 140000, 5.34800000, -4.00310000, 'Danga Sud', 65.00, NULL),
(16, 'Danga Centre, Avenue principale 3', 900000, 5.35020000, -4.00180000, 'Danga Centre', 28.00, NULL),
(17, 'Danga Centre, Avenue principale 4', 300000, 5.34990000, -4.00200000, 'Danga Centre', 32.00, NULL),
(18, 'Danga Résidentiel, Rue des Palmiers 3', 220000, 5.35190000, -3.99910000, 'Danga Résidentiel', 22.00, NULL),
(19, 'Danga Résidentiel, Rue des Palmiers 4', 150000, 5.35220000, -3.99880000, 'Danga Résidentiel', 24.00, NULL),
(20, 'Danga Extension, Rue des Manguiers 3', 100000, 5.34900000, -3.99820000, 'Danga Extension', 78.00, NULL),
(21, 'Danga21', 230000, NULL, NULL, 'Secteur21', 0.00, NULL),
(22, 'Danga22', 470000, NULL, NULL, 'Secteur22', 0.00, NULL),
(23, 'Danga23', 360000, NULL, NULL, 'Secteur23', 0.00, NULL),
(24, 'Danga24', 170000, NULL, NULL, 'Secteur24', 0.00, NULL),
(25, 'Danga25', 150000, NULL, NULL, 'Secteur25', 0.00, NULL),
(26, 'Danga26', 950000, NULL, NULL, 'Secteur26', 0.00, NULL),
(27, 'Danga27', 310000, NULL, NULL, 'Secteur27', 0.00, NULL),
(28, 'Danga28', 230000, NULL, NULL, 'Secteur28', 0.00, NULL),
(29, 'Danga29', 160000, NULL, NULL, 'Secteur29', 0.00, NULL),
(30, 'Danga30', 110000, NULL, NULL, 'Secteur30', 0.00, NULL),
(31, 'Danga31', 240000, NULL, NULL, 'Secteur31', 0.00, NULL),
(32, 'Danga32', 480000, NULL, NULL, 'Secteur32', 0.00, NULL),
(33, 'Danga33', 370000, NULL, NULL, 'Secteur33', 0.00, NULL),
(34, 'Danga34', 180000, NULL, NULL, 'Secteur34', 0.00, NULL),
(35, 'Danga35', 160000, NULL, NULL, 'Secteur35', 0.00, NULL),
(36, 'Danga36', 970000, NULL, NULL, 'Secteur36', 0.00, NULL),
(37, 'Danga37', 320000, NULL, NULL, 'Secteur37', 0.00, NULL),
(38, 'Danga38', 240000, NULL, NULL, 'Secteur38', 0.00, NULL),
(39, 'Danga39', 170000, NULL, NULL, 'Secteur39', 0.00, NULL),
(40, 'Danga40', 120000, NULL, NULL, 'Secteur40', 0.00, NULL),
(41, 'Danga41', 250000, NULL, NULL, 'Secteur41', 0.00, NULL),
(42, 'Danga42', 490000, NULL, NULL, 'Secteur42', 0.00, NULL),
(43, 'Danga43', 380000, NULL, NULL, 'Secteur43', 0.00, NULL),
(44, 'Danga44', 190000, NULL, NULL, 'Secteur44', 0.00, NULL),
(45, 'Danga45', 170000, NULL, NULL, 'Secteur45', 0.00, NULL),
(46, 'Danga46', 990000, NULL, NULL, 'Secteur46', 0.00, NULL),
(47, 'Danga47', 330000, NULL, NULL, 'Secteur47', 0.00, NULL),
(48, 'Danga48', 250000, NULL, NULL, 'Secteur48', 0.00, NULL),
(49, 'Danga49', 180000, NULL, NULL, 'Secteur49', 0.00, NULL),
(50, 'Danga50', 130000, NULL, NULL, 'Secteur50', 0.00, NULL),
(51, 'Danga51', 260000, NULL, NULL, 'Secteur51', 0.00, NULL),
(52, 'Danga52', 510000, NULL, NULL, 'Secteur52', 0.00, NULL),
(53, 'Danga53', 390000, NULL, NULL, 'Secteur53', 0.00, NULL),
(54, 'Danga54', 200000, NULL, NULL, 'Secteur54', 0.00, NULL),
(55, 'Danga55', 180000, NULL, NULL, 'Secteur55', 0.00, NULL),
(56, 'Danga56', 1000000, NULL, NULL, 'Secteur56', 0.00, NULL),
(57, 'Danga57', 340000, NULL, NULL, 'Secteur57', 0.00, NULL),
(58, 'Danga58', 260000, NULL, NULL, 'Secteur58', 0.00, NULL),
(59, 'Danga59', 190000, NULL, NULL, 'Secteur59', 0.00, NULL),
(60, 'Danga60', 140000, NULL, NULL, 'Secteur60', 0.00, NULL),
(61, 'Danga61', 270000, NULL, NULL, 'Secteur61', 0.00, NULL);

INSERT INTO Habitant (id_habitant, nom, prenom, sexe, date_de_naissance, profession, niveau_etude, telephone, statut, id_menage, position_menage, lien_avec_chef) VALUES
(51, 'Assi', 'Moussa', 'Masculin', '1994-09-27', 'Commerçant', 'Secondaire', '0700000201', 'actif', 20, NULL, NULL),
(3, 'Kouassi', 'Jean', 'Masculin', '1980-05-10', 'Comptable', 'Supérieur', '0700000001', 'actif', 1, NULL, NULL),
(4, 'Kouassi', 'Marie', 'Féminin', '1985-03-12', 'Commerçante', 'Secondaire', '0700000002', 'actif', 1, NULL, NULL),
(113, 'KOUADIO', 'samuel', 'Masculin', '1900-12-22', 'Comm', 'Primaire', '+2256555465655', 'actif', NULL, NULL, NULL),
(9, 'KONAN', 'Alice', 'Féminin', '1984-06-25', 'Enseignante', 'Licence', '0700000007', 'actif', 2, NULL, NULL),
(116, 'ZOH', 'ADIROU', 'Masculin', '2004-01-29', 'Etudiant', 'Aucun', '+2250141968564', 'actif', 18, NULL, NULL),
(5, 'Kouassi', 'Paul', 'Masculin', '2010-07-15', 'Élève', 'Primaire', '0700000003', 'actif', 1, NULL, NULL),
(6, 'Kouassi', 'Anne', 'Féminin', '2012-09-20', 'Élève', 'Primaire', '0700000004', 'actif', 1, NULL, NULL),
(7, 'Kouassi', 'Luc', 'Masculin', '2015-11-01', 'Élève', 'Aucun', '0700000005', 'actif', 1, NULL, NULL),
(8, 'Konan', 'Pierre', 'Masculin', '1978-04-11', 'Ingénieur', 'Supérieur', '0700000006', 'actif', 2, NULL, NULL),
(100, 'ASSI', 'Koffi', 'Masculin', '2010-02-20', 'Commerçant', 'Secondaire', '0700000481', 'decede', 48, NULL, NULL),
(114, 'KOUADI', 'Poyard', 'Masculin', '1900-12-22', 'Comm', 'Primaire', '+2256555465655', 'actif', NULL, NULL, NULL),
(15, 'Bamba', 'Serge', 'Masculin', '2021-08-29', 'Commerçant', 'Secondaire', '0700000021', 'parti', 2, NULL, NULL),
(10, 'Konan', 'Eric', 'Masculin', '2008-02-18', 'Élève', 'Secondaire', '0700000008', 'actif', 2, NULL, NULL),
(11, 'Konan', 'Lina', 'Féminin', '2011-08-30', 'Élève', 'Primaire', '0700000009', 'actif', 2, NULL, NULL),
(12, 'Konan', 'Yao', 'Masculin', '2016-01-05', 'Élève', 'Aucun', '0700000010', 'actif', 2, NULL, NULL),
(13, 'Bamba', 'Jean', 'Masculin', '1992-08-12', 'Commerçant', 'Secondaire', '0700000011', 'actif', 1, NULL, NULL),
(14, 'Kouassi', 'Ruth', 'Féminin', '1992-07-14', 'Élève', 'Primaire', '0700000012', 'actif', 1, NULL, NULL),
(16, 'Ouattara', 'Grace', 'Féminin', '1991-04-13', 'Élève', 'Primaire', '0700000022', 'actif', 2, NULL, NULL),
(17, 'Bamba', 'Jean', 'Masculin', '1980-11-23', 'Commerçant', 'Secondaire', '0700000031', 'actif', 3, NULL, NULL),
(18, 'Toure', 'Esther', 'Féminin', '1975-04-07', 'Élève', 'Primaire', '0700000032', 'actif', 3, NULL, NULL),
(19, 'Coulibaly', 'Franck', 'Masculin', '2013-08-19', 'Commerçant', 'Secondaire', '0700000041', 'actif', 4, NULL, NULL),
(20, 'Koffi', 'Awa', 'Féminin', '1993-08-18', 'Élève', 'Primaire', '0700000042', 'actif', 4, NULL, NULL),
(21, 'Yao', 'Ruth', 'Féminin', '1993-11-05', 'Commerçant', 'Secondaire', '0700000051', 'actif', 5, NULL, NULL),
(22, 'Diallo', 'Ruth', 'Féminin', '1980-01-10', 'Élève', 'Primaire', '0700000052', 'actif', 5, NULL, NULL),
(23, 'NGuessan', 'Fatou', 'Féminin', '1986-02-23', 'Commerçant', 'Secondaire', '0700000061', 'actif', 6, NULL, NULL),
(24, 'Ouattara', 'Ruth', 'Féminin', '1996-07-16', 'Élève', 'Primaire', '0700000062', 'actif', 6, NULL, NULL),
(25, 'Fofana', 'Fatou', 'Féminin', '1981-02-09', 'Commerçant', 'Secondaire', '0700000071', 'actif', 7, NULL, NULL),
(26, 'Fofana', 'Awa', 'Féminin', '1979-02-25', 'Élève', 'Primaire', '0700000072', 'actif', 7, NULL, NULL),
(27, 'Kone', 'Fatou', 'Féminin', '2022-07-30', 'Commerçant', 'Secondaire', '0700000081', 'actif', 8, NULL, NULL),
(28, 'Kone', 'Ibrahim', 'Masculin', '1992-10-29', 'Élève', 'Primaire', '0700000082', 'actif', 8, NULL, NULL),
(29, 'Toure', 'Paul', 'Masculin', '1984-04-28', 'Commerçant', 'Secondaire', '0700000091', 'actif', 9, NULL, NULL),
(31, 'Toure', 'David', 'Masculin', '2018-03-13', 'Commerçant', 'Secondaire', '0700000101', 'actif', 10, NULL, NULL),
(32, 'Kouadio', 'Grace', 'Féminin', '2014-03-31', 'Élève', 'Primaire', '0700000102', 'actif', 10, NULL, NULL),
(33, 'Traoré', 'Awa', 'Féminin', '1986-09-19', 'Commerçant', 'Secondaire', '0700000111', 'actif', 11, NULL, NULL),
(35, 'Traoré', 'Grace', 'Féminin', '1984-08-09', 'Commerçant', 'Secondaire', '0700000121', 'actif', 12, NULL, NULL),
(36, 'Yao', 'David', 'Masculin', '1980-03-11', 'Élève', 'Primaire', '0700000122', 'actif', 12, NULL, NULL),
(37, 'Zongo', 'Aminata', 'Féminin', '2016-05-23', 'Commerçant', 'Secondaire', '0700000131', 'actif', 13, NULL, NULL),
(39, 'Kone', 'Esther', 'Féminin', '1997-12-05', 'Commerçant', 'Secondaire', '0700000141', 'actif', 14, NULL, NULL),
(40, 'Sangare', 'Moussa', 'Masculin', '2016-12-01', 'Élève', 'Primaire', '0700000142', 'actif', 14, NULL, NULL),
(41, 'Fofana', 'Ruth', 'Féminin', '1987-04-16', 'Commerçant', 'Secondaire', '0700000151', 'actif', 15, NULL, NULL),
(69, 'Zongo', 'Koffi', 'Masculin', '2005-08-14', 'Commerçant', 'Secondaire', '0700000291', 'actif', 29, NULL, NULL),
(42, 'Kouadio', 'Franck', 'Masculin', '1997-01-30', 'Élève', 'Primaire', '0700000152', 'actif', 15, NULL, NULL),
(43, 'Konan', 'Paul', 'Masculin', '1995-06-20', 'Commerçant', 'Secondaire', '0700000161', 'actif', 16, NULL, NULL),
(44, 'Yao', 'Eric', 'Masculin', '1981-01-22', 'Élève', 'Primaire', '0700000162', 'actif', 16, NULL, NULL),
(45, 'Kone', 'Jean', 'Masculin', '2000-11-23', 'Commerçant', 'Secondaire', '0700000171', 'actif', 17, NULL, NULL),
(46, 'Sangare', 'Paul', 'Masculin', '1989-05-17', 'Élève', 'Primaire', '0700000172', 'actif', 17, NULL, NULL),
(47, 'NGuessan', 'Ibrahim', 'Masculin', '1981-04-15', 'Commerçant', 'Secondaire', '0700000181', 'actif', 18, NULL, NULL),
(48, 'Konan', 'Alice', 'Féminin', '1978-02-26', 'Élève', 'Primaire', '0700000182', 'actif', 18, NULL, NULL),
(49, 'Coulibaly', 'Nadia', 'Féminin', '2016-11-20', 'Commerçant', 'Secondaire', '0700000191', 'actif', 19, NULL, NULL),
(50, 'Diallo', 'Moussa', 'Masculin', '1982-03-06', 'Élève', 'Primaire', '0700000192', 'actif', 19, NULL, NULL),
(52, 'Coulibaly', 'Nadia', 'Féminin', '1996-02-17', 'Élève', 'Primaire', '0700000202', 'actif', 20, NULL, NULL),
(53, 'Ndiaye', 'Yao', 'Masculin', '1986-12-29', 'Commerçant', 'Secondaire', '0700000211', 'actif', 21, NULL, NULL),
(54, 'Traoré', 'Grace', 'Féminin', '1977-07-11', 'Élève', 'Primaire', '0700000212', 'actif', 21, NULL, NULL),
(55, 'Konan', 'Awa', 'Féminin', '2012-11-08', 'Commerçant', 'Secondaire', '0700000221', 'actif', 22, NULL, NULL),
(56, 'Konan', 'Esther', 'Féminin', '2007-07-26', 'Élève', 'Primaire', '0700000222', 'actif', 22, NULL, NULL),
(57, 'Kouassi', 'Yao', 'Masculin', '1988-12-13', 'Commerçant', 'Secondaire', '0700000231', 'actif', 23, NULL, NULL),
(58, 'Zongo', 'Grace', 'Féminin', '2015-09-13', 'Élève', 'Primaire', '0700000232', 'actif', 23, NULL, NULL),
(59, 'Sangare', 'Alice', 'Féminin', '1994-07-21', 'Commerçant', 'Secondaire', '0700000241', 'actif', 24, NULL, NULL),
(60, 'Koffi', 'Yao', 'Masculin', '1984-08-24', 'Élève', 'Primaire', '0700000242', 'actif', 24, NULL, NULL),
(62, 'Kouadio', 'Fatou', 'Féminin', '1993-04-17', 'Élève', 'Primaire', '0700000252', 'actif', 25, NULL, NULL),
(63, 'Diomande', 'Moussa', 'Masculin', '2008-03-30', 'Commerçant', 'Secondaire', '0700000261', 'actif', 26, NULL, NULL),
(64, 'Assi', 'Moussa', 'Masculin', '2012-07-06', 'Élève', 'Primaire', '0700000262', 'actif', 26, NULL, NULL),
(66, 'Zongo', 'Alice', 'Féminin', '1984-04-22', 'Élève', 'Primaire', '0700000272', 'actif', 27, NULL, NULL),
(68, 'Zongo', 'Awa', 'Féminin', '1998-03-16', 'Élève', 'Primaire', '0700000282', 'actif', 28, NULL, NULL),
(70, 'Konan', 'Nadia', 'Féminin', '1993-11-26', 'Élève', 'Primaire', '0700000292', 'actif', 29, NULL, NULL),
(71, 'Soro', 'Ibrahim', 'Masculin', '1980-04-18', 'Commerçant', 'Secondaire', '0700000301', 'actif', 30, NULL, NULL),
(72, 'Coulibaly', 'Yao', 'Masculin', '1979-04-12', 'Élève', 'Primaire', '0700000302', 'actif', 30, NULL, NULL),
(74, 'Ndiaye', 'Serge', 'Masculin', '2019-02-04', 'Élève', 'Primaire', '0700000312', 'actif', 31, NULL, NULL),
(75, 'Zongo', 'Grace', 'Féminin', '2002-12-23', 'Commerçant', 'Secondaire', '0700000321', 'actif', 32, NULL, NULL),
(76, 'Koffi', 'David', 'Masculin', '1994-02-09', 'Élève', 'Primaire', '0700000322', 'actif', 32, NULL, NULL),
(77, 'Koffi', 'Franck', 'Masculin', '1997-06-30', 'Commerçant', 'Secondaire', '0700000331', 'actif', 33, NULL, NULL),
(78, 'Diallo', 'Jean', 'Masculin', '2023-08-11', 'Élève', 'Primaire', '0700000332', 'actif', 33, NULL, NULL),
(79, 'Toure', 'Moussa', 'Masculin', '2005-10-10', 'Commerçant', 'Secondaire', '0700000341', 'actif', 34, NULL, NULL),
(80, 'NGuessan', 'Marie', 'Féminin', '1976-04-05', 'Élève', 'Primaire', '0700000342', 'actif', 34, NULL, NULL),
(81, 'Yao', 'Clarisse', 'Féminin', '1999-01-13', 'Commerçant', 'Secondaire', '0700000351', 'actif', 35, NULL, NULL),
(82, 'Toure', 'Paul', 'Masculin', '1989-10-29', 'Élève', 'Primaire', '0700000352', 'actif', 35, NULL, NULL),
(83, 'Soro', 'Ruth', 'Féminin', '2022-10-01', 'Commerçant', 'Secondaire', '0700000361', 'actif', 36, NULL, NULL),
(84, 'NGuessan', 'Ruth', 'Féminin', '1987-03-11', 'Élève', 'Primaire', '0700000362', 'actif', 36, NULL, NULL),
(85, 'Sangare', 'Moussa', 'Masculin', '2011-11-08', 'Commerçant', 'Secondaire', '0700000371', 'actif', 37, NULL, NULL),
(86, 'Coulibaly', 'David', 'Masculin', '2023-09-26', 'Élève', 'Primaire', '0700000372', 'actif', 37, NULL, NULL),
(87, 'Traoré', 'Grace', 'Féminin', '1992-06-07', 'Commerçant', 'Secondaire', '0700000381', 'actif', 38, NULL, NULL),
(88, 'Coulibaly', 'Grace', 'Féminin', '2012-02-19', 'Élève', 'Primaire', '0700000382', 'actif', 38, NULL, NULL),
(90, 'Toure', 'Eric', 'Masculin', '1984-05-04', 'Élève', 'Primaire', '0700000392', 'actif', 39, NULL, NULL),
(91, 'Ndiaye', 'Grace', 'Féminin', '1995-09-23', 'Commerçant', 'Secondaire', '0700000401', 'actif', 40, NULL, NULL),
(92, 'Ouattara', 'Eric', 'Masculin', '1998-09-01', 'Élève', 'Primaire', '0700000402', 'actif', 40, NULL, NULL),
(93, 'Soro', 'Clarisse', 'Féminin', '2020-08-09', 'Commerçant', 'Secondaire', '0700000411', 'actif', 41, NULL, NULL),
(94, 'Yao', 'Ibrahim', 'Masculin', '1987-02-11', 'Commerçant', 'Secondaire', '0700000421', 'actif', 42, NULL, NULL),
(96, 'Sangare', 'Yao', 'Masculin', '1985-11-29', 'Commerçant', 'Secondaire', '0700000441', 'actif', 44, NULL, NULL),
(97, 'NGuessan', 'Yao', 'Masculin', '2013-07-06', 'Commerçant', 'Secondaire', '0700000451', 'actif', 45, NULL, NULL),
(98, 'Kone', 'Ruth', 'Féminin', '2022-11-30', 'Commerçant', 'Secondaire', '0700000461', 'actif', 46, NULL, NULL),
(99, 'Kouadio', 'Clarisse', 'Féminin', '1997-08-16', 'Commerçant', 'Secondaire', '0700000471', 'actif', 47, NULL, NULL),
(101, 'Fofana', 'Moussa', 'Masculin', '2011-12-02', 'Commerçant', 'Secondaire', '0700000491', 'actif', 49, NULL, NULL),
(102, 'Toure', 'Grace', 'Féminin', '2003-04-05', 'Commerçant', 'Secondaire', '0700000501', 'actif', 50, NULL, NULL),
(103, 'Ndiaye', 'Koffi', 'Masculin', '2008-12-02', 'Commerçant', 'Secondaire', '0700000511', 'actif', 51, NULL, NULL),
(104, 'Koffi', 'Clarisse', 'Féminin', '1999-12-09', 'Commerçant', 'Secondaire', '0700000521', 'actif', 52, NULL, NULL),
(105, 'Diallo', 'Aminata', 'Féminin', '1984-11-06', 'Commerçant', 'Secondaire', '0700000531', 'actif', 53, NULL, NULL),
(106, 'Soro', 'Paul', 'Masculin', '2007-03-07', 'Commerçant', 'Secondaire', '0700000541', 'actif', 54, NULL, NULL),
(108, 'Traoré', 'Grace', 'Féminin', '1980-08-14', 'Commerçant', 'Secondaire', '0700000561', 'actif', 56, NULL, NULL),
(109, 'Yao', 'David', 'Masculin', '1979-10-12', 'Commerçant', 'Secondaire', '0700000571', 'actif', 57, NULL, NULL),
(110, 'Konan', 'Ibrahim', 'Masculin', '1986-10-27', 'Commerçant', 'Secondaire', '0700000581', 'actif', 58, NULL, NULL),
(111, 'Sangare', 'Aminata', 'Féminin', '1995-01-06', 'Commerçant', 'Secondaire', '0700000591', 'actif', 59, NULL, NULL),
(112, 'Ndiaye', 'Esther', 'Féminin', '1982-05-27', 'Commerçant', 'Secondaire', '0700000601', 'actif', 60, NULL, NULL),
(95, 'ASSI', 'Ibrahim', 'Masculin', '1960-11-11', 'Commerçant', 'Secondaire', '0700000431', 'actif', 43, NULL, NULL),
(107, 'Zongo', 'Nadia', 'Féminin', '2017-07-02', 'Commerçant', 'Secondaire', '0700000551', 'decede', 55, NULL, NULL),
(65, 'Bamba', 'Clarisse', 'Féminin', '1998-01-16', 'Commerçant', 'Secondaire', '0700000271', 'decede', 27, NULL, NULL),
(67, 'Coulibaly', 'Fatou', 'Féminin', '2022-07-08', 'Commerçant', 'Secondaire', '0700000281', 'decede', 28, NULL, NULL),
(89, 'Coulibaly', 'Esther', 'Féminin', '1987-02-07', 'Commerçant', 'Secondaire', '0700000391', 'decede', 39, NULL, NULL),
(115, 'OUATTARA', 'Paul', 'Masculin', '0001-01-01', 'Commerçant', 'Secondaire', '+225585889966', 'actif', NULL, NULL, NULL);

INSERT INTO Evenement_vital (id_evenement, type_evenement, date_evenement, description, id_habitant) VALUES
(9, 'deces', '2026-05-18', NULL, 65),
(10, 'naissance', '2026-01-22', NULL, 13),
(11, 'naissance', '2026-01-22', NULL, 105),
(12, 'deces', '2026-01-02', NULL, 107),
(13, 'deces', '2026-02-28', NULL, 67),
(14, 'deces', '2026-04-10', NULL, 89),
(15, 'deces', '2025-09-22', NULL, 100),
(17, 'naissance', '2026-05-22', NULL, 64),
(18, 'naissance', '2026-05-22', NULL, 64);

INSERT INTO Mouvement_residuel (id_mouvement, type_mouvement, date_mouvement, provenance, destination, id_habitant) VALUES
(2, 'arrivee', '2026-05-16', 'Koumassi', 'Cocody', 51),
(10, 'depart', '2026-05-28', 'Danga1', 'youpougon', 15);

INSERT INTO utilisateurs (id_utilisateur, username, password, role, label, email, date_creation) VALUES
(6, 'agent', '$2b$12$RCCSVVbsadiW1rOpViLJiOLrm1F78zzuL6JK.pXR18Gmn276kQ0qe', 'agent', 'Agent de collecte', 'agent@gmail.com', '2026-05-17 21:29:14.779391'),
(7, 'responsable', '$2b$12$UhusBMBF1KgQBw5FCZczg.YHUWJhmhyXAV14CcR6RtqoCkO0gFAwC', 'responsable', 'Responsable local', 'resp@gmail.com', '2026-05-17 21:29:14.779391'),
(5, 'admin', '$2b$12$TwxGQfMOqDnIPOLr1ZZpiutKmFfTt3SJKeGIioZjqAURu9yivIrZ6', 'admin', 'Administrateur', 'mfad09012002@gmail.com', '2026-05-17 21:29:14.779391'),
(8, 'hote', '$2b$12$ja1xMwFuahyuUqSZ.MfpM.jGBWkYrgMlLHNzbykAXxYHqqaRmznAS', 'hote', 'hote', 'mfond.adirou@gmail.com', '2026-05-17 21:29:14.779391');


-- Réinitialisation des séquences SERIAL après insertion manuelle des ID
SELECT setval(pg_get_serial_sequence('Menages', 'id_menage'), COALESCE((SELECT MAX(id_menage) FROM Menages), 1), true);
SELECT setval(pg_get_serial_sequence('Habitant', 'id_habitant'), COALESCE((SELECT MAX(id_habitant) FROM Habitant), 1), true);
SELECT setval(pg_get_serial_sequence('Evenement_vital', 'id_evenement'), COALESCE((SELECT MAX(id_evenement) FROM Evenement_vital), 1), true);
SELECT setval(pg_get_serial_sequence('Mouvement_residuel', 'id_mouvement'), COALESCE((SELECT MAX(id_mouvement) FROM Mouvement_residuel), 1), true);
SELECT setval(pg_get_serial_sequence('utilisateurs', 'id_utilisateur'), COALESCE((SELECT MAX(id_utilisateur) FROM utilisateurs), 1), true);
SELECT setval(pg_get_serial_sequence('historique_actions', 'id'), COALESCE((SELECT MAX(id) FROM historique_actions), 1), true);

-- Contrôles rapides
SELECT COUNT(*) AS total_menages FROM Menages;
SELECT COUNT(*) AS total_habitants FROM Habitant;
SELECT COUNT(*) AS total_evenements FROM Evenement_vital;
SELECT COUNT(*) AS total_mouvements FROM Mouvement_residuel;
SELECT COUNT(*) AS total_utilisateurs FROM utilisateurs;
