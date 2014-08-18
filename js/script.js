var uagent = navigator.userAgent.toLowerCase();

var w, h;
if( screen.width <= 480 ) {
    //is iphone
    w = 180;
    h = 180;
}else{
    w = 600;
    h = 600;
}

var colorscale = d3.scale.ordinal()
    .domain(["foo", "bar", "baz"])
    .range(["#66C4C1","#F57CD5","#333"]);

//Legend titles
var LegendOptions = ['8hrs ago','New'];

//Data
var d = [
      [
      {axis:"Relationship",value:<%=@oldR%>},
      {axis:"Professional",value:<%=@oldP%>},
      {axis:"Social",value:<%=@oldS%>}
      ],[
      {axis:"Relationship",value:0.48},
      {axis:"Professional",value:0.41},
      {axis:"Social",value:0.27}
      ]
    ];

//Options for the Radar chart, other than default
var mycfg = {
  w: w,
  h: h,
  maxValue: 0.6,
  levels: 6,
  ExtraWidthX: 300
}

//Call function to draw the Radar chart
//Will expect that data is in %'s
RadarChart.draw("#chart", d, mycfg);

////////////////////////////////////////////
/////////// Initiate legend ////////////////
////////////////////////////////////////////

var svg = d3.select('#body')
  .selectAll('svg')
  .append('svg')
  .attr("width", w+300)
  .attr("height", h)

//Create the title for the legend
var text = svg.append("text")
  .attr("class", "title")
  .attr('transform', 'translate(90,0)') 
  .attr("x", w - 70)
  .attr("y", 10)
  .attr("font-size", "12px")
  .attr("fill", "#404040")
  .text("");
    
//Initiate Legend 
var legend = svg.append("g")
  .attr("class", "legend")
  .attr("height", 100)
  .attr("width", 200)
  .attr('transform', 'translate(90,20)') 
  ;
  //Create colour squares
  legend.selectAll('rect')
    .data(LegendOptions)
    .enter()
    .append("rect")
    .attr("x", w - 45)
    .attr("y", function(d, i){ return i * 20;})
    .attr("width", 10)
    .attr("height", 10)
    .style("fill", function(d, i){ return colorscale(i);})
    ;
  //Create text next to squares
  legend.selectAll('text')
    .data(LegendOptions)
    .enter()
    .append("text")
    .attr("x", w - 32)
    .attr("y", function(d, i){ return i * 20 + 9;})
    .attr("font-size", "18px")
    .attr("fill", "#737373")
    .text(function(d) { return d; })
    ; 