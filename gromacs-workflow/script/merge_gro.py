#!/usr/bin/env python3

def complex_preparation(protein_gro, ligand_gro_list, out_file):
    """Merge protein and ligand GRO files into a single complex structure."""
    atoms_list = []
    with open(protein_gro) as input:
        prot_data = input.readlines()
        atoms_list.extend(prot_data[2:-1])

    for f in ligand_gro_list:
        with open(f) as input:
            data = input.readlines()
        atoms_list.extend(data[2:-1])

    n_atoms = len(atoms_list)
    with open(out_file, 'w') as output:
        output.write(prot_data[0])
        output.write(f'{n_atoms}\n')
        output.write(''.join(atoms_list))
        output.write(prot_data[-1])

if __name__ == "__main__":
    protein = "protein.gro"
    ligands = ["ligand.gro"]
    output = "complex.gro"

    complex_preparation(protein, ligands, output)
    print(f"Complex structure saved to {output}")
