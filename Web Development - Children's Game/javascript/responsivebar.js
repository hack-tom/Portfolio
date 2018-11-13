/*
Written By: Alexander Chapman
*/

/*Function to expand dropdown menu when Menu button is pressed*/
function dropdownMenu() {
	/*Stores a reference to the list of nav items*/
    var menu = document.getElementById("MainNav");
	/*Add to the element the movileview class. This will enable properties in main.css which when clicked disp*/
    if (menu.className === "navbar") {
        menu.className = menu.className+" mobileview";
    } 
	/*Otherwise just leave class name as navbar. Do not add dropdown properties (mobileview) class.*/
	else {
        menu.className = "navbar";
    }
}