#!/usr/bin/env python3

from flask import Blueprint, render_template, request


main = Blueprint('main', __name__)


@main.route("/")
def index():
    return render_template('index.html')

@main.route("/predict", methods=["POST"])
def predict():
    if request.method == 'POST':
        smiles = request.form.get("smiles")
        protein = request.form.get("protein")
        
        print(f"Received SMILES: {smiles}\nProtein: {protein}")
    
    return f"Received SMILES: {smiles}\nProtein sequence:{protein}\nProtein length: {len(protein)}" 
    