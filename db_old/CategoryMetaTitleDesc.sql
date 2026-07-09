UPDATE category
SET
    meta_title = CASE slug
        WHEN 'eduteam'      THEN 'EduTeams - Microsoft Teams provisioning in het onderwijs'
        WHEN 'mysite'       THEN 'MySite - Eigen CMS met Perl en Dancer2'
        WHEN 'brood'        THEN 'Desem brood - Ambacht, techniek en experimenteren'
        WHEN 'electronics'  THEN 'ESP32 - Microcontrollers en hardware experimenten'
        WHEN 'mprjv65'      THEN 'Mprjv65 - k3s, Kubernetes en cloudplatformen'
        WHEN 'ptl'          THEN 'PTL - Perl Template Language en automatisering'
    END,
    meta_description = CASE slug
        WHEN 'eduteam' THEN
            'EduTeams gaat over het modelleren en automatiseren van Microsoft Teams provisioning in het onderwijs, met Microsoft 365, Magister en HelloID.'
        WHEN 'mysite' THEN
            'MySite beschrijft het bouwen van een eigen CMS met Perl, Dancer2, SQLite en Markdown, inclusief webarchitectuur, observability en SEO.'
        WHEN 'brood' THEN
            'Desem brood gaat over bakken als ambacht: techniek, proces, tijd, aandacht en experimenteren zonder scherm.'
        WHEN 'electronics' THEN
            'ESP32 bevat experimenten met microcontrollers, hardware-automatisering en praktische toepassingen zoals een time-lapse camera voor desem.'
        WHEN 'mprjv65' THEN
            'Mprjv65 volgt experimenten met k3s, Kubernetes en een eigen cloud stack, met focus op reproduceerbaarheid, governance en observability.'
        WHEN 'ptl' THEN
            'PTL bevat artikelen over Perl, scripting, automatisering en softwareontwikkeling vanuit een pragmatische praktijkbenadering.'
    END
WHERE slug IN ('eduteam','mysite','brood','electronics','mprjv65','ptl');