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
import qualified Data.ByteString.Lazy as BS
import qualified Data.ByteString.Lazy.Char8 as L8
import qualified System.Directory as SD
import Network.HTTP.Client
import Network.HTTP.Client.TLS
import Network.HTTP.Types.Status  (statusCode)
import System.FilePath
import Data.String ( fromString )
import Control.Monad
import Data.Aeson (Value, encode, object, (.=))
import Data.Text

-- data for Json Types
--
--data UserLogin = UserLogin {
--  status    :: Int
--, message   :: Text
--, datafield :: Text--Maybe UserData
--} deriving Show
--
--data UserData = UserData {
--  user :: User
--, token :: String
--}
--
--data User = User {
--  id        :: Text
--, username  :: Text
--} deriving Show
--
--data Customer = Customer {
--  name  :: Text
--, email :: Text
--, phone :: Text
--} deriving Show
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


main :: IO ()
main = do
  manager <- newManager tlsManagerSettings
  let requestObject = object
            [ "username" .= ("Alice" :: String)
            , "password" .= ("Boring" :: String)
            ]
  initialRequest <- parseRequest "http://localhost:3000/users/register"
  let request = initialRequest
          { method = "POST"
          , requestBody = RequestBodyLBS $ encode requestObject
          , requestHeaders =
              [ ("Content-Type", "application/json; charset=utf-8")
              ]
          }
  response <- httpLbs request manager
  putStrLn $ "The status code was: "
          ++ show (statusCode $ responseStatus response)
  L8.putStrLn $ responseBody response


  let requestObject2 = object
            [ "username" .= ("Alice" :: String)
            , "password" .= ("Boring" :: String)
            ]
  secondRequest <- parseRequest "http://localhost:3000/users/authenticate"
  let request2 = secondRequest
          { method = "POST"
          , requestBody = RequestBodyLBS $ encode requestObject2
          , requestHeaders =
              [ ("Content-Type", "application/json; charset=utf-8")
              ]
          }
  response2 <- httpLbs request2 manager
  putStrLn $ "The status code was: "
          ++ show (statusCode $ responseStatus response2)
  L8.putStrLn $ responseBody response2


  let requestObject3 = object
            [ "userId" .= ("5c2255e15dedab2a1c888082" :: String)
            , "name" .= ("Boring" :: String)
            , "email" .= ("test"  :: String)
            , "phone" .= ("1d1a"  :: String)
            ]
  thirdRequest <- parseRequest "http://localhost:3000/customers/authenticate"
  --let token = 
  let request3 = thirdRequest
          { method = "POST"
          , requestBody = RequestBodyLBS $ encode requestObject3
          , requestHeaders =
              [ ("Content-Type", "application/json; charset=utf-8"),
                ("x-access-token", "key to be extracted")
              ]
          }
  response3 <- httpLbs request3 manager
  putStrLn $ "The status code was: "
          ++ show (statusCode $ responseStatus response3)
  L8.putStrLn $ responseBody response3
  putStrLn $ "hi"

