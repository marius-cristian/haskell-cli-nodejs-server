//MIKKEL any reason for the solver function ? I see you use
//it for postprocessing the result..this could be made this could be made shorter

exports.generic_handler = (req,res,next,promise,solver)=>{
  promise.then(function(result){
    //Why this ? 
    let df = null
    df = solver.call(this, result)
    res.json({status:200, message:"Ok.", datafield:df});
  }).catch(function(err){next(err);});
};
