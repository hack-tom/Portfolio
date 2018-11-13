/*
Written By: Alexander Chapman
*/

function pageArtResize(){
//Gets the overlayed absolute positioned element.
var footerImage = document.getElementById("footerimage");
//Gets the page footer.
var footerHolder = document.getElementById("site-footer");
//Sets footerHeight variable to the height of the art.
var footerHeight = footerImage.height;
footerHolder.style.marginTop = footerHeight+"px"
}

pageArtResize();