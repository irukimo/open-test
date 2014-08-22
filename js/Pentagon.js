    function Pentagon(DimensionArray, time_difference,oldColor, newColor, bodyID, chartID, hashBodyID, hashChartID){
        var uagent = navigator.userAgent.toLowerCase();

        var w, h;
        var isIphone;
        if( screen.width <= 480 ) {
            // chartelement = document.getElementById(chartID);
            // chartelement.style.paddingLeft = "3px";
            //is iphone
            w = 160;
            h = 160;
            isIphone = true;
        }else{
            chartelement = document.getElementById(chartID);
            chartelement.style.paddingLeft = "20px";
            w = 350;
            h = 350;
            isIphone = false;
        }

        var colorscale = d3.scale.ordinal()
            .domain(["foo", "bar", "baz"])
            .range([oldColor,newColor,"#333"]);

        //Legend titles
        var LegendOptions = [time_difference,'最新'];

        //Data
        var d = DimensionArray;
        // var d = [
        //       [
        //       {axis:"Relationship",value:<%=@oldR%>},
        //       {axis:"Professional",value:<%=@oldP%>},
        //       {axis:"Social",value:<%=@oldS%>}
        //       ],[
        //       {axis:"Relationship",value:<%=@newR%>},
        //       {axis:"Professional",value:<%=@newP%>},
        //       {axis:"Social",value:<%=@newS%>}
        //       ]
        //     ];

        //Options for the Radar chart, other than default
        var mycfg = {
          w: w,
          h: h,
          // maxValue: 0.6,
          // levels: 6,
          maxValue: 1,
          levels: 3,
          ExtraWidthX: 300,
          //cannot be more than 300
          svgWidth:(isIphone)? 300: 630,
          svgHeight:(isIphone)? 300: 450,
          color:colorscale,
          //how faraway are the legends to the graph
          factorLegend: (isIphone)?.65:.85,
          //xoffset of whole diagram
          TranslateX: (isIphone)?65:120,
        }

        //Call function to draw the Radar chart
        //Will expect that data is in %'s
        RadarChart.draw(hashChartID, d, mycfg);

        ////////////////////////////////////////////
        /////////// Initiate legend ////////////////
        ////////////////////////////////////////////

        var svg = d3.select(hashBodyID)
          .selectAll('svg')
          .append('svg')
          .attr("width", w+300)
          .attr("height", h+300)

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
            //change x offset
            .attr("x", (isIphone)? (w - 190) : (w - 53))
            .attr("y", function(d, i){ return i * 20 + ((isIphone)?220:100) ;})
            .attr("width", 10)
            .attr("height", 10)
            .style("fill", function(d, i){ return colorscale(i);})
            ;
          //Create text next to squares
          legend.selectAll('text')
            .data(LegendOptions)
            .enter()
            .append("text")
            //change x offset
            .attr("x", (isIphone)? (w - 177) : (w-40))
            .attr("y", function(d, i){ return i * 20 + ((isIphone)?229:109);})
            .attr("font-size", "18px")
            .attr("fill", "#737373")
            .text(function(d) { return d; })
            ; 

    }

