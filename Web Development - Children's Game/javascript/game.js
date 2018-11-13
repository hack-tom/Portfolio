/*
Written By: Alexander Chapman
*/
	
	/*Declared variables used throughout the program*/
	
	/*Setup variables*/
	/*Stores data in game board. Will hold which square is which color.*/
	var data = [[-1,-1,-1,-1],[-1,-1,-1,-1],[-1,-1,-1,-1],[-1,-1,-1,-1]];
	/*Holds whether square can be clicked during current turn*/
	var squareEnabled=[[true,true,true,true],[true,true,true,true],[true,true,true,true],[true,true,true,true]];
	/*Holds canvas info as objects*/
	var canvas = document.getElementById("mycanvas");
	var context = canvas.getContext("2d");
	/*Holds player score*/
	var playerScore = 0;
	/*Object detailing each selection the user makes when they click on the canvas*/
	var firstSelection = {value:null, column:null, row:null};
	var secondSelection = {value:null, column:null, row:null};
	//Sets canvas height and width
	canvas.setAttribute("width", viewportDimensions());
	canvas.setAttribute("height", viewportDimensions());
	/*Gets canvas height and width from inline style*/
	var WIDTH = canvas.width;
	var HEIGHT = canvas.height;
	
	/*Calls function setting up game board*/
	gameSetupHandler();
	
	/*Calls getSelection function with click information as parameter whenever user clicks on page.*/
	canvas.addEventListener('click', getSelection);


function getSelection(evt) {
		/*Gets width of a square on canvas*/
		var sqWidth = WIDTH/data.length;
		/*Gets position on canvas where user has clicked*/
		var pos = GetPos(evt);
		/*Translates position clicked into local coordinates (rows/columns)*/
		var squarePos = GetSquarePos(pos);
		
		/*If the turn is accepted (i.e square hasn't already been revealed), turn over card and make the card non-clickable*/
		if(squarePos.goodturn==true){
			var colour = gridColour(data[squarePos.row][squarePos.column]);
			/*Is this the user's first turn in a pair of turns?*/
			if (firstSelection.value==null){
				/*Reveals square showing hidden color*/
				firstSelection.value = data[squarePos.row][squarePos.column];
				firstSelection.column = squarePos.column;
				firstSelection.row = squarePos.row;
				/*Draws the cell in its hidden color.*/
				drawCell(squarePos.column*sqWidth, squarePos.row*sqWidth, sqWidth,sqWidth, colour);
				/*Makes card non-clickable for subsequent turn*/
				squareEnabled[firstSelection.row][firstSelection.column] = false;
			}
			/*Must be second turn of pair*/
			else {
				/*Repeats above setting of variables and redrawing of square but for second turn*/
				secondSelection.value = data[squarePos.row][squarePos.column];
				secondSelection.column = squarePos.column;
				secondSelection.row = squarePos.row;
				drawCell(squarePos.column*sqWidth, squarePos.row*sqWidth, sqWidth,sqWidth, colour);
				/*If user doesn't select a matching square, output a message to tell them that and re-enable reset both selected squares*/
				if (firstSelection.value!=secondSelection.value){
					alert('Not A Valid Combination')
					drawCell(firstSelection.column*sqWidth, firstSelection.row*sqWidth, sqWidth,sqWidth, "#000000");
					drawCell(secondSelection.column*sqWidth, secondSelection.row*sqWidth, sqWidth,sqWidth, "#000000");
					squareEnabled[firstSelection.row][firstSelection.column] = true;
					squareEnabled[secondSelection.row][secondSelection.column] = true;
				}
				/*If selected matching squares, reveal both permanently*/
				else{
					squareEnabled[firstSelection.row][firstSelection.column] = false;
					squareEnabled[secondSelection.row][secondSelection.column] = false;
					playerScore = playerScore+1;
				}
				/*Clear turn variables ready for next turn.*/
				clearFirst();
				clearSecond();
			}	
		}
		/*If turn not accepted (clicks card revealed already) nullify the turn and ask the user for another input.*/
		else{
			if (firstSelection.value==null){
			squareEnabled[firstSelection.row][firstSelection.column] = true;		
			clearFirst()
			}
			else {
			clearSecond()
			}
		}
		
		checkScore();
}

/*Clears the user's first input selection for a pair of inputs*/
function clearFirst(){
	firstSelection.value = null;
	firstSelection.column = null;
	firstSelection.row = null;
}

/*Clears the user's second input selection*/
function clearSecond(){
	secondSelection.value = null;
	secondSelection.column = null;
	secondSelection.row = null;
}

/*Checks player score and outputs animation once the player has won*/
function checkScore(){
	if (playerScore>=8){
		alert('WINNER');
		/*Reset score*/
		playerScore = 0;
		/*Reset Game Board*/
		data = [[-1,-1,-1,-1],[-1,-1,-1,-1],[-1,-1,-1,-1],[-1,-1,-1,-1]];
		/*Reset clickable grid*/
		squareEnabled=[[true,true,true,true],[true,true,true,true],[true,true,true,true],[true,true,true,true]];
		gameSetupHandler();
	}	
}


/***************/
/*Mouse Handler*/
/***************/

/*Gets coordinates of user click on canvas using click data passed into formal parameter e*/
/*This function has been edited from an example in Lecture 16 - Graphics On Canvas Part 2 see full attribution on references page*/
function GetPos(e){
	/*Gets canvas element stores reference in variable*/
	var canvas =  document.getElementById("mycanvas");
	/*Stores canvas position relative to viewport in object*/
	var boundingRect = canvas.getBoundingClientRect();	
	/*Offsets determine how far from coordinates (0,0) in viewport the canvas is placed*/
	var offsetX = boundingRect.left;
	var offsetY = boundingRect.top;
	/*Determines width and height of canvas*/
	var w = (boundingRect.width-canvas.width)/2;
	var h = (boundingRect.height-canvas.height)/2;
	/*Adds width and height values to offsets*/
	offsetX += w;
	offsetY += h;
	/*Derrives local canvas coordinates for the click event*/
	var mx = Math.round(e.clientX-offsetX);
	var my = Math.round(e.clientY-offsetY);
	/*Returns localized canvas coordinates as an object*/
	return {x: mx, y: my};
}

/*Converts coordinates of where user clicked into local board coordinates (columns and rows)
Checks if the square has already been matched in this game. Returns this value along with column 
and row local coordinates stored in an object.*/
function GetSquarePos(clickPos){
		/*length stores length of a local unit with relation to canvas size*/
		var length = WIDTH/4;
		/*Generates a local x and y coordinate*/
		var x = Math.floor(clickPos.x/length);
		var y = Math.floor(clickPos.y/length);
		/*Decides whether the user can click this square*/
		if (squareEnabled[y][x]==true){
			var turnAccepted = true;
		}
		else{
			var turnAccepted = false;
		}
		/*Returns object*/
		return {column: x, row: y, goodturn:turnAccepted};
}
	

	
/*************/
	/*Setup*/
/*************/


/*Game Setup*/
function gameSetupHandler(){
	numberGen();
	canvasSetup();
}
/*Function for coloring a square. Am I still used?*/
function colorSquare(selectedCard){
	console.log("THIS SQUARE IS : " +data[selectedCard.column][selectedCard.row]);
	var sqWidth = WIDTH/data.length;
	var xTop = sqWidth * selectedCard.column;
	var yTop = 	sqWidth * selectedCard.row;
	drawCell(xTop, yTop, sqWidth, sqWidth, "#000000")
}

/*Generates random positions on the board for each pair of colored squares*/
function numberGen(){
	/*Loops through each color/pair of quares*/
	for (i=0;i<8;i++){
		
		do
		{
			/*Gets a random x and y coordinate on the board*/
			var row = Math.floor(Math.random()*4)
			var column = Math.floor(Math.random()*4)
		/*Checks square doesnt't already contain a color. Otherwise loops and generates new values*/
		}while(data[column][row] != -1)
		
		/*Inserts color at randomly generated coordinates*/
		data[column][row] = i;
		
		/*Repeats above algorithm for second cell in pair.*/
		do{
			var row = Math.floor(Math.random()*4)
			var column = Math.floor(Math.random()*4)
		}while(data[column][row] != -1)
			
		data[column][row] = i;		
	}

	/* DEBUG TOOL
	for (var i=0; i<4; i++){
		for (var j=0; j<4; j++){
			console.log("Column: "+i+" Row:"+j);
			console.log(data[i][j]);
		}
	}
	*/
}

/*Sets the height and width of the canvas to 80vmin. Handled here rather than by stylesheet as
canvas width and height at collected from the inline style that loads with the element rather than the css file.*/
function viewportDimensions(){
	/*Captures width and height of viewport*/
	viewportWidth = window.innerWidth;
	viewportHeight = window.innerHeight;
	/*Outputs 80% of whichever of the two variables has smallest value.*/
	if (viewportWidth<viewportHeight){
		return (viewportWidth*0.8)+"px";
	}
	else{
		return (viewportHeight*0.8)+"px";
	}
}


/*Graphical Setup*/
function canvasSetup(){
	drawGrid(context, data);
}

/*Iterates across the length of the data array (16 squares) to draw grid*/
/*This function has been edited from an example in Lecture 16 - Graphics On Canvas Part 2 see full attribution on references page*/
function drawGrid(context, grid) {
	var w = WIDTH/data.length;
	for (var i=0; i<data.length; ++i) {
		var h = HEIGHT/data[i].length;
		for (var j=0; j<data[i].length; ++j) {
			var colour = "#000000";
			drawCell(j*w, i*h, w, h, colour); 
		} 
	}
	/*Debug Tool Draws Grid*/
	//console.log(data[0][0]+" "+ data[0][1]+" "+data[0][2]+" "+data[0][3])
	//console.log(data[1][0]+" "+ data[1][1]+" "+data[1][2]+" "+data[1][3])
	//console.log(data[2][0]+" "+ data[2][1]+" "+data[2][2]+" "+data[2][3])
	//console.log(data[3][0]+" "+ data[3][1]+" "+data[3][2]+" "+data[3][3])
	/*---------------------*/
}

/*Draws an individual cell on the grid using even divisions of the viewport width and height (from drawGrid function.)*/
/*This function has been edited from an example in Lecture 16 - Graphics On Canvas Part 2 see full attribution on references page*/
function drawCell(x, y, width, height, c) {
/*Sets fill color to hex color passed into function.*/
context.fillStyle = c;
/*Fills a rectangle on the canvas in the correct color using canvas width and height to ensure equal sized grid squares*/
context.fillRect(x, y, width, height);
}

/*Sets the color of a square in the grid. (DONE)*/
function gridColour(data){
	switch(data)
	{
		case 0:
		return "#ffac81"
		break;		
		case 1:
		return "#ff928b"
		break;		
		case 2:
		return "#fec3a6"
		break;	
		case 3:
		return "#efe9ae"
		break;	
		case 4:
		return "#cdeac0"
		break;	
		case 5:
		return "#7871aa  "
		break;	
		case 6:
		return "#55868c"
		break;
		case 7:
		return "#eadeda"
		break;			
	}
}