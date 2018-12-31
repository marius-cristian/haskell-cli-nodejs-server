exports.generic_handler = (req,res,next,promise,solver)=>{
  promise.then(function(result){
    let df = null
    df = solver.call(this, result)
    res.json({status:200, message:"Ok.", datafield:df});
  }).catch(function(err){next(err);});
};