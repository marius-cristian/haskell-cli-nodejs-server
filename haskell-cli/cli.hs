#!/usr/bin/env stack
{- stack
   --resolver lts-12.6
   --install-ghc
   runghc
   --package http-client-tls
   --package filepath
   --package aeson
-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE Arrows #-}

import qualified Data.ByteString.Lazy as BS
import qualified Data.ByteString.Lazy.Char8 as L8
import qualified Data.ByteString.Char8 as C8
import qualified System.Directory as SD
import Network.HTTP.Client
import Network.HTTP.Client.TLS
import Network.HTTP.Types.Status  (statusCode)
import System.FilePath
import Data.String ( fromString )
import Control.Monad (forM, liftM)
import Data.Aeson (Value, encode, object, (.=))
import Data.Text

-- data for Json Types
data UserLogin = UserLogin {
  status    :: Int
, message   :: Text
, datafield :: Maybe UserData
} deriving Show
--
data UserData = UserData {
  user :: User
, token :: String
} deriving Show
--
data User = User {
  id        :: Text
, username  :: Text
} deriving Show

data Customer = Customer {
  name  :: Text
, email :: Text
, phone :: Text
} deriving Show
--
--
--instance FromJSON UserLogin where
--    parseJSON (Object v) =
--        Photo <$> v .: "status"
--              <*> v .: "message"
--              <*> v .: "data"
--    parseJSON _ = mzero
--
--instance FromJSON UserData where
--    parseJSON (Object v) =
--        Photo <$> v .: "_id"
--              <*> v .: "username"
--    parseJSON _ = mzero
--
--instance FromJSON Customer where
--    parseJSON (Object v) =
--        Photo <$> v .: "name"
--              <*> v .: "email"
--              <*> v .: "phone"
--    parseJSON _ = mzero    
--
--  extractToken :: (UserLogin u) => String
--  extractToken (UserLogin status message datafield) =
--    case datafield of
--      Just (UserData user token) -> show token
--      Nothing -> show "wrong datatype"
--  
--  extractUserId :: (UserLogin u) => String
--  extractUserId (UserLogin status message datafield) =
--    case datafield of
--decodeJSONField :: String -> String -> Maybe String
--decodeJSONField json field = do
--  result <- decode json
--  flip parseMaybe result $ \obj -> do
--    fld <- obj .: field
--    return (show fld) 


register :: String
register = "http://localhost:3000/users/register"

login :: String
login = "http://localhost:3000/users/authenticate"

customers :: String
customers = "http://localhost:3000/customers"

customerSearch :: String -> String
customerSearch src = "http://localhost:3000/customers/" ++ src 

tokenPath :: FilePath
tokenPath = "./tmp/.jwt-token"

main :: IO ()
main = do
  manager <- newManager tlsManagerSettings
  loopOver manager
--  let requestObject = object
--            [ "username" .= ("Alice" :: String)
--            , "password" .= ("Boring" :: String)
--            ]
--  initialRequest <- parseRequest "http://localhost:3000/users/register"
--  let request = initialRequest
--          { method = "POST"
--          , requestBody = RequestBodyLBS $ encode requestObject
--          , requestHeaders =
--              [ ("Content-Type", "application/json; charset=utf-8")
--              ]
--          }
--  response <- httpLbs request manager
--  putStrLn $ "The status code was: "
--          ++ show (statusCode $ responseStatus response)
--  L8.putStrLn $ responseBody response
--
--
--  let requestObject2 = object
--            [ "username" .= ("Alice" :: String)
--            , "password" .= ("Boring" :: String)
--            ]
--  secondRequest <- parseRequest "http://localhost:3000/users/authenticate"
--  let request2 = secondRequest
--          { method = "POST"
--          , requestBody = RequestBodyLBS $ encode requestObject2
--          , requestHeaders =
--              [ ("Content-Type", "application/json; charset=utf-8")
--              ]
--          }
--  response2 <- httpLbs request2 manager
--  putStrLn $ "The status code was: "
--          ++ show (statusCode $ responseStatus response2)
--  L8.putStrLn $ responseBody response2
--
--
--  let requestObject3 = object
--            [ "id" .= ("5c2255e15dedab2a1c888082" :: String)
--            , "name" .= ("Boring" :: String)
--            , "email" .= ("test"  :: String)
--            , "phone" .= ("1d1a"  :: String)
--            ]
--  thirdRequest <- parseRequest "http://localhost:3000/customers/authenticate"
--  --let token = 
--  let request3 = thirdRequest
--          { method = "POST"
--          , requestBody = RequestBodyLBS $ encode requestObject3
--          , requestHeaders =
--              [ ("Content-Type", "application/json; charset=utf-8"),
--                ("x-access-token", "key to be extracted")
--              ]
--          }
--  response3 <- httpLbs request3 manager
--  putStrLn $ "The status code was: "
--          ++ show (statusCode $ responseStatus response3)
--  L8.putStrLn $ responseBody response3
  putStrLn $ "Ok Bye."


-- build user request
requestUser :: String -> String -> Value
requestUser uname pwd = object
            [ "username" .= (uname :: String)
            , "password" .= (pwd :: String)
            ]

-- customer request object
requestCustomer :: String -> String -> String -> Value
requestCustomer name email phone = object
                [ "name"  .= (name :: String)
                , "email" .= (email :: String)
                , "phone" .= (phone :: String)
                ]

-- this is VERY BAD
-- i havent managed to solve the type of the output
-- to be m Request
-- thus I cut corner and dumped IO()
-- input: manager, url, token or empty string, body object
buildPOSTRequest :: Manager -> String -> String -> Value -> IO ()
buildPOSTRequest manager url tkn obj =
  do
    req <- parseRequest url
    let freq = req {method = "POST"
      ,requestBody = RequestBodyLBS $ encode obj
      ,requestHeaders =
        [ ("Content-Type", "application/json; charset=utf-8")
        , ("x-access-token", C8.pack tkn)
        ]
      }
    response <- httpLbs freq manager
    putStrLn $ "The status code was: "
          ++ show (statusCode $ responseStatus response)
    L8.putStrLn $ responseBody response

-- CLI loop
loopOver :: Manager -> IO()
loopOver manager = do
  showUsage
  input <- fmap (Prelude.map read.(Prelude.words)) getLine
  case input of
    ["cust", "register", username, password] -> do 
      let usr = requestUser username password
      -- again VERY BAD as i add empty token "" instead of masking
      -- it in buildPOSTRequest
      buildPOSTRequest manager register "" usr
      loopOver manager
    ["cust", "login", username, password] -> do 
      let usr = requestUser username password
      -- should modify in order to write to file the token
      -- i am really bad
      buildPOSTRequest manager login "" usr
      loopOver manager
    ["cust", "new", name, email, phone] -> do
      let customer = requestCustomer name email phone
      -- i really hate my life
      -- must implement readToken
      let tkn = readToken tokenPath
      buildPOSTRequest manager customers customer
      loopOver manager
    -- this other 2 should be in 
    ["cust", "list"] -> do putStrLn "Ok Bye!"
    ["cust", "search", str] -> do putStrLn "Ok Bye!"
    ["quit"] -> do putStrLn "Ok Bye!"
    _ -> do
      showUsage
      loopOver manager


-- TODO READ TOKEN FROM FILE
-- APPEND IT FOR USER REQUESTS

readToken :: FilePath -> String
readToken = undefined

-- here must parse strings in 1 string, not separate
showUsage :: IO()
showUsage =
  do
    putStrLn "\n\n"
    putStrLn "Commands:"
    putStrLn "\"cust\" \"register\" \"<username>\" \"<password>\""
    putStrLn "\"cust\" \"login\" \"<username>\" \"<password>\""
    putStrLn "\"cust\" \"new\" \"<name>\" \"<email>\" \"<phone>\""
    putStrLn "\"cust\" \"list\""
    putStrLn "\"cust\" \"search\" \"<string>\""
    putStrLn "\"quit\""
    putStrLn "\n\n"