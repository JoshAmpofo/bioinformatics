#!/usr/bin/env python3

"""
Write a program that will print only the accession names that satisfy the 
ff criteria - treat each criterion separately:
    - contain the number 5
    - contain the letter d or e
    - contain the letters d and e in that order
    - contain the letters d and e in that order with a single letter between them
    - contain both the letters d and e in any order
    - start with x or y
    - start with x or y and end with e
    - contain three or more digits in a row
    - end with d followed by either a, r or p
"""
import re


def search_for_five(accessions: list) -> str:
    """
    Search for accession names that contain the number 5
    
    Arg(s):
        accessions (list): list containing accession names
    
    Return(s):
        str: accession names that contain the number 5
    """
    # search for names that contain the number 5
    results = []
    for accession in accessions:
        patterns = re.search(r"5", accession)
        if patterns:
            results.append(accession)
    return results


def search_d_or_e(accessions: list) -> str:
    """
    search for d or e in accession names
    
    Arg(s):
        accessions (list): list containing accession names
    
    Return(s):
        str: accession names extracted containing d or e
    """
    # search for names that contain the letter d or e
    results = []
    for accession in accessions:
        patterns = re.search(r"(.+)[de](.+)", accession)
        if patterns:
            results.append(accession)
    return results


def search_d_and_e(accessions: list) -> list:
    """
    Search for accession names containing d and e in that order
    
    Arg(s):
        accessions (list): list containing accession names
    
    Return(s):
        list: accession names extracted containing d and e
    """
    # search for names that contain the letter d and e in that order
    results = []
    for accession in accessions:
        patterns = re.search(r"d.*e", accession)
        if patterns:
            results.append(accession)
    return results


def search_d_and_e_with_one_letter_in_between(accessions: list) -> list:
    """
    Search for accession names containing d and e with one letter in between
    
    Arg(s):
        accessions (list): list containing accession names
    
    Return(s):
        list: accession names extracted containing d and e with one letter in between
    """
    # search for names that contain the letter d and e with one letter in between
    results = []
    for accession in accessions:
        patterns = re.search(r"d.e", accession)
        if patterns:
            results.append(accession)
    return results


def search_d_and_e_in_any_order(accessions: list) -> list:
    """
    Search for accession names containing d and e in any order
    
    Arg(s):
        accessions (list): list containing accession names
    
    Return(s):
        list: accession names extracted containing d and e in any order
    """
    # search for names that contain the letter d and e in any order
    results = []
    for accession in accessions:
        patterns = re.search(r"d.*e", accession) or re.search(r"e.*d", accession)
        if patterns:
            results.append(accession)
    return results


def start_with_x_or_y(accessions: list) -> list:
    """
    Search for accession names starting with x or y
    
    Arg(s):
        accessions (list): list containing accession names
    
    Return(s):
        list: accession names extracted starting with x or y
    """
    # search for names that start with x or y
    results = []
    for accession in accessions:
        patterns = re.search(r"^[xy].+", accession)
        if patterns:
            results.append(accession)
    return results


def start_with_x_or_y_end_with_e(accessions: list) -> list:
    """
    Search for accession names starting with x or y and ending with e
    
    Arg(s):
        accessions (list): list containing accession names
    
    Return(s):
        list: accession names extracted starting with x or y and ending with e
    """
    # search for names that start with x or y and end with e
    results = []
    for accession in accessions:
        patterns = re.search(r"^[xy].+e$", accession)
        if patterns:
            results.append(accession)
    return results


def contain_three_or_more_digits(accessions: list) -> list:
    """
    Search for accession names containing three or more digits in a row
    
    Arg(s):
        accessions: list containing accession names
    
    Return(s):
        list: extracted accession names containing three or more digits in a row
    """
    results = []
    # search for pattern matching three or more digits in a row
    for accession in accessions:
        patterns = re.search(r"[0-9]{3,}", accession)
        if patterns:
            results.append(accession)
    return results


def end_with_d_a_r_or_p(accessions: list) -> list:
    """
    Search for accession names ending with d followed by either a, r or p
    
    Arg(s):
        accessions (list): list containing accession names
    
    Return(s):
        list: accession names extracted ending with d followed by either a, r or p
    """
    # search for names that end with d followed by either a, r or p
    results = []
    for accession in accessions:
        patterns = re.search(r"d[arp]$", accession)
        if patterns:
            results.append(accession)
    return results

# Test the functions
if __name__ == "__main__":
    accessions = ['xkn59438', 'yhdck2', 'eihd39d9', 'chdsye847', 'hedle3455', 'xjhd53e', '45da', 'de37dp']
    print(f"Accession names containing the number 5: {search_for_five(accessions)}")
    print(f"Accession names containing the letter d or e: {search_d_or_e(accessions)}")
    print(f"Accession names containing the letters d and e in that order: {search_d_and_e(accessions)}")
    print(f"Accession names containing the letters d and e in that order with a single letter between them: {search_d_and_e_with_one_letter_in_between(accessions)}")
    print(f"Accession names containing both the letters d and e in any order: {search_d_and_e_in_any_order(accessions)}")
    print(f"Accession names starting with x or y: {start_with_x_or_y(accessions)}")
    print(f"Accession names starting with x or y and ending with e: {start_with_x_or_y_end_with_e(accessions)}")
    print(f"Accession names containing three or more digits in a row: {contain_three_or_more_digits(accessions)}")
    print(f"Accession names ending with d followed by either a, r or p: {end_with_d_a_r_or_p(accessions)}")