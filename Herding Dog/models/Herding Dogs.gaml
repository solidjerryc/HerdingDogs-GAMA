/***
* Name: HerdingDogs
* Author: caiboqin
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model HerdingDogs

/* Insert your model definition here */

global
{ 
	/**
	 * Read shape files
	 */
	//file sheepPastureStart <- shape_file("../includes/sheep-pasture-start/sheep-pasture-start.shp");
	file sheepPastureOpen <- shape_file("../includes/sheep-pasture-open/sheep-pasture.shp");
	file sheepPoly <- shape_file("../includes/../includes/sheep-poly/sheep-poly.shp");
	file gate <- shape_file("../includes/../includes/gate(3)/gate.shp");
	
	float actionDis <- 10.0 min: 1.0 max: 20.0;
	float basicSpeed<- 2.0 min: 0.5 max: 5.0;
	
	
	list<float> sheepdis; 
	
	float dogDis<-0.0;
	
	geometry shape <- envelope(sheepPastureOpen);
	geometry sheepPolyShape <- geometry(sheepPastureOpen);
	
	//geometry pasture<- sheepPastureStart[1];// with:[height::float(get("HEIGHT")), type::string(get("NATURE"))] ;
	
	int sheepInRate<-0;
	int sheepLastTime<-0;
	int sheepFlow <- 0;
	bool cycleCount<-false;
	
	init{
		create sheepPasture from: sheepPastureOpen;
		create sheepPolyShp from: sheepPoly;
		create gateObj from: gate;
		create sheep number:100 {
			location <- any_location_in(one_of(sheepPoly));
		}
		create dog number:3 {
			location <- any_location_in(one_of(sheepPastureOpen[0]));
			speed <- 2.0;
		}
	}
	
	reflex countMySheep{
		int countNum<-0;
		
		sheepInRate<-0;
		ask sheep{
			if(self.isIn)
			{
				sheepInRate<-sheepInRate+1;
				countNum<-countNum+1;
			}
		}
		
		// Output the cycle number when it finished
		if(countNum=100 and !cycleCount){
			write "It takes "+ cycle +" cycles to get all sheep in pasture.";
			cycleCount<-true;
			do pause;
		}
		// Count flow of the sheep that running into the gate.
		sheepFlow<-countNum-sheepLastTime;
		sheepLastTime<-countNum;
	}
	
	// Sum up the total distance of all dogs
	reflex dogDistance{
		ask dog{
			dogDis <- dogDis+self.speed;
		}
	}
	
	// Snapshot of the number of sheep in the pasture at cycle 400.
	reflex snapShotOfSheep{
		if(cycle=400){
			int numOfSheepInPasture<-0;
			ask sheep{
				if(self.isIn){
					numOfSheepInPasture<-numOfSheepInPasture+1;
				}
			}
			write "There are " + numOfSheepInPasture + " sheep in pasture at cycle 400.";
		}
	}
}

species sheep skills: [ moving ]{
	float vision <- 30.0;
	float wanderRange <- 10.0;
	
	list<sheep> mySheepsInMyVision;
	list<sheep> mySheepsNear;
	list<dog> myDogs;
	bool isIn <- false;
	
	geometry myBounds<- geometry(sheepPastureOpen[0]);
	
	reflex runTogether{
		geometry perceived_area <- circle(vision);
		mySheepsInMyVision <- sheep overlapping perceived_area;
		mySheepsNear<- sheep overlapping circle(wanderRange);
		myDogs<- dog overlapping circle(actionDis);
	}
	
	reflex getIn{
		//write geometry(gate).location;
		ask (sheep overlapping geometry(gate)){
			if(!isIn){
			    isIn<-true;
			    //do goto target: {133,101};
			}
		}
	}
	
	reflex move{

		if(isIn){
			// If a sheep is in the pasture, it just wander.
			do wander amplitude:110.0 bounds: sheepPastureOpen[1];
		}
        else if(length(mySheepsNear)<3 and length(mySheepsInMyVision)>2){
        	/**
        	 * If there are more than 2 sheep in this sheep's vision area 
        	 * and less than 3 sheep near this sheep, it runs to the group.
        	 */
        	int gotoIndex<-rnd(length(mySheepsInMyVision)-1);
			if(!mySheepsInMyVision[gotoIndex].isIn){
			    do goto target: mySheepsInMyVision[gotoIndex].location;    
			}else{
				// Else condition, sheep will go towards the gate.
				do goto target: geometry(gate).location;
			}
		}else if(length(myDogs)>0){
			// If any dog in the sheep's vision, it will run to the gate
			do goto target: geometry(gate).location;
		}//if(length(mySheepsNear)>=3)
		else{
			// If many sheep get together, they do wandering.
		    do wander amplitude:110.0 bounds: myBounds;
		} 
	}
	
	aspect default{
		draw circle(1) color: #red;
	}
}

species dog skills: [ moving ]{
	
	int gotoIndex<-0;
	list targetLocList;
	
	reflex findDistantSheep{
		// Find the furthest 10 sheep and store their location in a list.
		float maxValue<-0.0;
		int maxIndex<-0;
		ask sheep{
			float dis<-distance_to(self.location, geometry(gate).location);
			if(dis>maxValue and !self.isIn){
				maxValue<-dis;
				add self.location to: myself.targetLocList;
				// Control the length of list less than 10
				if(length(myself.targetLocList)>10){
					myself.targetLocList[] >- 0;
				}
			}else{
				
			}
		}
	}
	
	reflex move{
		if(cycleCount=true){
			speed<-0.0;
		}
		else if(rnd(5)>4){
			speed <- 0.5;
			do wander amplitude:90.0 bounds: geometry(sheepPastureOpen[0]);
		}else{
			speed <- basicSpeed;
			do goto target: one_of(targetLocList);//targetSheepLoc;
		}
		//write speed;
		/*if(length(mySheep)<=0 and rnd(5)>4){
			do wander speed:0.2 amplitude:30.0 bounds: geometry(sheepPastureOpen[0]);
		}else{
			gotoIndex<-rnd(length(mySheep)-1);
			if(!mySheep[gotoIndex].isIn){
		        do goto target: targetSheepLoc;//mySheep[gotoIndex].location;
		    }else{
		    	do wander speed:0.2 amplitude:30.0 bounds: geometry(sheepPastureOpen[0]);
		    }
		}*/
	}
	aspect default{
		draw circle(1) color: #black;
	}
}

/**
 * The visualization object of the base shape
 */
species sheepPasture {
	aspect base {
		draw shape color:#lightblue border: #black;
	}	
}

species sheepPolyShp {
	aspect base {
		draw shape color:#lightgreen;
	}	
}

species gateObj {
	aspect base {
		draw shape color:#red;
	}	
}

experiment simulation type: gui {
	parameter 'Action distance of sheep ' var: actionDis;
	parameter 'Basic speed of dogs ' var: basicSpeed;
	
	// Time series plot for the 
	output {
		display "Speed"  background: #white {
			chart "Number of sheep" type: series {
			    data "How many sheep in the pasture." value:  sheepInRate;
			}
			
			//chart "Running distance of dogs" type: series {
			//    data "Distance" value:  dogDis;
			//}
		}
		
		display "Flow"  background: #white {
			chart "Number of sheep" type: series {
			    data "Flow (n sheep per cycle)" value:  sheepFlow;
			}
		}
		
		display "Running distance of dogs"  background: #white {
			chart "Running distance of dogs" type: series {
			    data "Distance" value:  dogDis;
			}
		}
		
 		display map {
			//Draw shp on canvas;
			species sheepPasture aspect:base;
			species sheepPolyShp aspect:base;
			species gateObj aspect:base;
			
			species sheep aspect:default;
			species dog aspect:default;
		}
	}
}