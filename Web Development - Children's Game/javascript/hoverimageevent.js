/*
Written By: Alexander Chapman
*/

/*Stores rederence to a card containing game icon, which text will be overlayed onto*/
var gameCard = document.getElementById("HoverImage");
/*When user's mouse is hovered over a card run this function displaying text*/
gameCard.addEventListener("mouseover", OnHover);
/*When user's mouse is no longer hovered over a card run this function to remove displayed text*/
gameCard.addEventListener("mouseout", OffHover);

function OnHover()
{   
   document.getElementByClass("HoverImage").setAttribute("style", "display:block;")
}

function OffHover()
{  
    document.getElementByClass("HoverImage").setAttribute("style", "display:none;")