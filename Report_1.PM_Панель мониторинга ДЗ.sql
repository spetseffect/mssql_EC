--------------------------------------
--DECLARE @Planning UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000000';
--DECLARE @UserId UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000000';
--------------------------------------
DECLARE @plan UNIQUEIDENTIFIER = IIF(@Planning IS NULL,
										(SELECT npl_problemassetsrepaymentsplanningId 
											FROM npl_problemassetsrepaymentsplanningBase 
											WHERE npl_completed_at=(SELECT MAX(npl_completed_at) FROM npl_problemassetsrepaymentsplanningBase)),
										@Planning
									);
--
DECLARE @userRoles TABLE(roleName NVARCHAR(100));
INSERT INTO @userRoles
	SELECT rb.[Name]
		FROM SystemUserRoles sur
			JOIN RoleBase rb ON rb.RoleId = sur.RoleId
		WHERE sur.SystemUserId=@UserId;
DECLARE @userTeams TABLE(teamName NVARCHAR(100));
INSERT INTO @userTeams
	SELECT tm.TeamId
		FROM TeamMembership tm
		WHERE tm.SystemUserId=@UserId;
DECLARE @subordinateUsers TABLE(suid UNIQUEIDENTIFIER);
INSERT INTO @subordinateUsers
	SELECT su.SystemUserId
		FROM SystemUserBase su
			JOIN SystemUserRoles sur ON sur.SystemUserId=su.SystemUserId
			JOIN RoleBase rb ON rb.RoleId=sur.RoleId
		WHERE su.BusinessUnitId=(SELECT sub.BusinessUnitId
									FROM SystemUserBase sub
									WHERE sub.SystemUserId=@UserId)
			AND rb.[Name]='Syst_Collection_Співробітник РУ';
---
SELECT 
		MainUnit = bu.[Name]--1
		,PIB_Name = rbpa.npl_fullname--2
		,EDRPOU_RNOKPP = rbpa.npl_ConAccNumbe--3
		,DebtorType = CASE rbpa.npl_flagConnAcc	WHEN 1 THEN 'Фізична особа'
												WHEN 2 THEN 'Юридична особа'
												WHEN 3 THEN 'Підприємець'
												WHEN 4 THEN 'Самозайнята особа'
						END--4
		,BalanceAcc = cdd.npl_account_overdue--5
		,AccNumber = cdd.coll_contract_number--6
		,ConclusionDate = cdd.coll_contract_date--7
		,DebtType = (SELECT [Value] 
						FROM StringMapBase 
						WHERE AttributeName = 'npl_type_of_receivables' 
							AND [LangId] = 1058 
							AND AttributeValue = cdd.npl_type_of_receivables)--8
		,RefABS = cdd.coll_contract_number--9
		,Currency = tc.ISOCurrencyCode--10
		,DebtSumOnDateNom = rbpa.npl_DebtAmountOnDate--11
		,DebtSumOnDateEqv = rbpa.npl_arrears_uah--12
		,DebtDate = ISNULL(cdd.coll_date_problem_loan, cdd.npl_date_problem_overdue)--13
		,ResponsRefund = su.FullName--14
		,AccaountingType = IIF(cdd.coll_date_problem_loan IS NULL,'На балансі','Списаний')--15
		,AccaountingDate = cdd.npl_datewoff--16
		,PerspectiveLess = CASE cdd.npl_unpromising	WHEN 0 THEN 'Ні'
													WHEN 1 THEN 'Так'
								END--17
		,PerspectiveLessCat = (SELECT [Value] 
									FROM StringMapBase 
									WHERE AttributeName = 'npl_unpromisingtype' 
										AND [LangId] = 1058
										AND AttributeValue = cdd.npl_unpromisingtype)--18
		,Unpromising = (SELECT [Value]
							FROM StringMapBase 
							WHERE AttributeName = 'npl_unpromising ' 
								AND LangId = 1058 
								AND AttributeValue = rbpa.npl_unpromising)--19
		,UnpromisingType = (SELECT [Value]
								FROM StringMapBase
								WHERE AttributeName = 'npl_unpromisingtype'
									AND [LangId] = 1058
									AND AttributeValue = rbpa.npl_UnpromisingType)--20
		,Q1 = rbpa.npl_AmountPaidQuarter1--21
		,M1 = rbpa.npl_AmountPaidByDecomissionnedM1--22
		,M2 = rbpa.npl_AmountPaidByDecomissionnedM2--23
		,M3 = rbpa.npl_AmountPaidByDecomissionnedM3--24
		,Q2 = rbpa.npl_AmountPaidQuarter2--25
		,M4 = rbpa.npl_AmountPaidByDecomissionnedM4--26
		,M5 = rbpa.npl_AmountPaidByDecomissionnedM5--27
		,M6 = rbpa.npl_AmountPaidByDecomissionnedM6--28
		,Q3 = rbpa.npl_AmountPaidQuarter3--29
		,M7 = rbpa.npl_AmountPaidByDecomissionnedM7--30
		,M8 = rbpa.npl_AmountPaidByDecomissionnedM8--31
		,M9 = rbpa.npl_AmountPaidByDecomissionnedM9--32
		,Q4 = rbpa.npl_AmountPaidQuarter4--33
		,M10 = rbpa.npl_AmountPaidByDecomissionnedM10--34
		,M11 = rbpa.npl_AmountPaidByDecomissionnedM11--35
		,M12 = rbpa.npl_AmountPaidByDecomissionnedM12--36
		,YearNom = rbpa.npl_amountplannedyear_total--37
		,YearEkv = rbpa.npl_amountplannedyear_total_eqw--38
	FROM npl_RepaymentsByProblemAssetsBase rbpa
		LEFT JOIN coll_debit_debtBase cdd					ON cdd.coll_debit_debtId = rbpa.npl_coll_debit_debtId
		LEFT JOIN BusinessUnitBase bu						ON bu.BusinessUnitId = rbpa.npl_BusinessUnitId
		LEFT JOIN TransactionCurrencyBase tc				ON tc.TransactionCurrencyId = cdd.TransactionCurrencyId
		LEFT JOIN SystemUserBase su							ON su.SystemUserId = cdd.npl_systemuserid
	WHERE rbpa.npl_AssetType = 923360001
		AND rbpa.npl_PARepaymentsPlanningId=@plan
		AND (
				('Syst_Collection_Співробітник РУ' IN (SELECT * FROM @userRoles)
					AND 'Collection_Адміністратор системи' NOT IN (SELECT * FROM @userRoles)
					AND 'Collection_Керівник ДРЗС' NOT IN (SELECT * FROM @userRoles)
					AND 'Syst_Collection_Керівник_РУ' NOT IN (SELECT * FROM @userRoles)
					AND 'Системный администратор' NOT IN (SELECT * FROM @userRoles)
					AND 'Syst_Collection_Аналітик РУ' NOT IN (SELECT * FROM @userRoles)
					AND rbpa.npl_systemuserid = @UserId
				) OR
				('Collection_Адміністратор системи' IN (SELECT * FROM @userRoles)
					OR 'Collection_Керівник ДРЗС' IN (SELECT * FROM @userRoles)
					OR 'Системный администратор' IN (SELECT * FROM @userRoles)
				) OR
				(('Collection_Співробітник ДРЗС' IN (SELECT * FROM @userRoles) OR 'Syst_Collection_Viewer' IN (SELECT * FROM @userRoles))
					AND 'Collection_Адміністратор системи' NOT IN (SELECT * FROM @userRoles)
					AND 'Collection_Керівник ДРЗС' NOT IN (SELECT * FROM @userRoles)
					AND 'Системный администратор' NOT IN (SELECT * FROM @userRoles)
					AND 'Syst_Collection_Керівник РУ ' NOT IN (SELECT * FROM @userRoles)
					AND 'Syst_Collection_Аналітик РУ' NOT IN (SELECT * FROM @userRoles)
					AND rbpa.OwnerId IN (SELECT * FROM @userTeams)
				) OR
				(('Syst_Collection_Керівник_РУ' IN (SELECT * FROM @userRoles) OR 'Syst_Collection_Аналітик РУ' IN (SELECT * FROM @userRoles))
					AND 'Collection_Адміністратор системи' NOT IN (SELECT * FROM @userRoles)
					AND 'Collection_Керівник ДРЗС' NOT IN (SELECT * FROM @userRoles)
					AND 'Системный администратор' NOT IN (SELECT * FROM @userRoles)
					AND (rbpa.OwnerId IN (SELECT * FROM @userTeams)	
							OR rbpa.npl_systemuserid  IN (SELECT * FROM @subordinateUsers)
						)
				)
			)