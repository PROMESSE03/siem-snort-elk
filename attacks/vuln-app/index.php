<?php
/**
 * Page web volontairement vulnérable — LAB UNIQUEMENT.
 * Elle n'exécute AUCUNE vraie requête SQL : elle ne sert qu'à recevoir
 * des URL contenant des motifs d'injection pour que Snort les détecte.
 */
$id = isset($_GET['id']) ? $_GET['id'] : '1';

header('Content-Type: text/html; charset=utf-8');
?>
<!doctype html>
<html lang="fr">
<head><meta charset="utf-8"><title>Lab — Catalogue produits</title></head>
<body>
  <h1>Catalogue produits (démo lab)</h1>
  <p>Produit demandé : id = <?php echo htmlspecialchars($id); ?></p>
  <p>Essayez : <code>/index.php?id=1</code></p>
  <hr>
  <small>Environnement de test — ne pas exposer sur Internet.</small>
</body>
</html>
