-- SPDX-FileCopyrightText: 2021 Tezos Commons
-- SPDX-License-Identifier: LicenseRef-MIT-TC

module Test.Ligo.TreasuryDAO.Types
  ( TransferProposal (..)
  , TreasuryDaoProposalMetadata (..)
  ) where

import Universum

import Lorentz as L

import Ligo.BaseDAO.Common.Types
import Ligo.BaseDAO.Types

{-# ANN module ("HLint: ignore Reduce duplication" :: Text) #-}

data TransferProposal = TransferProposal
  { tpAgoraPostId :: Natural
  , tpTransfers :: [TransferType]
  }

instance HasAnnotation TransferProposal where
  annOptions = baseDaoAnnOptions

customGeneric "TransferProposal" ligoLayout

deriving anyclass instance IsoValue TransferProposal

-- | Helper type for unpack/pack
data TreasuryDaoProposalMetadata
  = Transfer_proposal TransferProposal
  | Update_guardian Address
  | Update_contract_delegate (Maybe KeyHash)

instance HasAnnotation TreasuryDaoProposalMetadata where
  annOptions = baseDaoAnnOptions

customGeneric "TreasuryDaoProposalMetadata" ligoLayout
deriving anyclass instance IsoValue TreasuryDaoProposalMetadata
