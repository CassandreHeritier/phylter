# Phylter, a tool for analyzing, visualizing and filtering phylogenomics datasets. 

..* Phylter is written in R language with dependencies on the 'ape' and 'Rspectra' packages.
..* Phylter relies on DIstatis (Abdi et al, 2005), an extension of multidimensional scaling to 3 dimensions. It allows comparing multiple distance matrices (on the same set of elements) at once. 



---
### references
Abdi, H., Valentin, D., O’Toole, A.J., & Edelman, B. (2005). DISTATIS: The analysis of multiple distance matrices. Proceedings of the IEEE Computer Society: International Conference on Computer Vision and Pattern Recognition. (San Diego, CA, USA). pp. 42–47.




SimOutliersHGT(tree, nbgn, outgn, outsp, outcell, sp = 0)
SimOutliersLg(tree, nbgn, outgn, outsp, outcell, sp = 0)

tree = Arbre d'espèce
nbgn = nombre de gènes souhaité
outgn = nombre d'outliers gènes souhaité
outsp = nombre d'outliers espèces souhaité
outcell = nombre d'outliers cell souhaité
sp = 1 si HGT sur les branches externes uniquement / 0 sinon

	-VIZ : Code d'une méthode de visualisation des gènes et des espèces codé par Damien.

	-PHYLTER : prémisses du package PhylteR. Le code est dans PhylteR/R

	-CLUSTER :

		- ARBRES : Ensemble des listes arbres (numéroté de 1 à 5550). Ce sont des arbres de 100 gènes à 30 espèces. Provenant de 3 arbres d'espèces différents.
			- plan.csv = a quoi correspondent les liste d'arbres en fonction de leurs numéro. Arbres d'espèces => tree1 = ArbreSym.phy / tree2 = ArbreAsym.phy / tree3 = ArbreRandom.phy
			- Les dossiers tree0 à tree4 contiennen les listes d'arbres de 1 à 4500. C'est a dire les arbres contenant ou non des outliers complets.
			- Le dossier treeOutcell ne contient que les listes d'arbres numérotées de 4501 à 5555 contenant les outliers cell (et pas d'outliers complets)

		-SCRIPT : Différents scripts ayant servis à générer les listes d'arbres simulées sur le cluster
		
		-FORETS : jeux de données réèls
		

--> Pour éditer le code du shiny, penser à demander l'acces au svn à Aurélie ou à Stéphane.

