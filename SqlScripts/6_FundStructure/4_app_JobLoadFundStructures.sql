CREATE OR ALTER PROCEDURE [dbo].[app_JobLoadFundStructures]
AS BEGIN
    Declare @Contract_id Int, @ErrorMessage NVarChar(max);

    -- курсор
    declare CntCur cursor fast_forward for
        select
            D.ID as Contract_Id
        from [BAL_DATA_STD].[dbo].od_faces as F with(nolock)
        inner join [BAL_DATA_STD].[dbo].D_B_CONTRACTS as C with(nolock) ON F.self_ID = C.INVESTOR
        LEFT JOIN [BAL_DATA_STD].[dbo].OD_DOCS as D with(nolock) ON C.DOC = D.ID
        LEFT JOIN [BAL_DATA_STD].[dbo].OD_SHARES as S with(nolock) ON  S.ISSUER = F.SELF_ID
        where
            F.LAST_FLAG = 1 AND C.I_TYPE = 5 AND C.E_DATE > GETDATE() AND F.E_DATE > GETDATE() AND S.E_DATE > GetDate()
            AND D.ID <> 541875
        group by D.ID
        order by D.ID
    open CntCur
    fetch next from CntCur into @Contract_Id
    while @@FETCH_STATUS = 0
    begin
        BEGIN TRY
            EXEC [dbo].[app_LoadFundStructure]
                @Contract_id = @Contract_id
        END TRY
        BEGIN CATCH
            SET @ErrorMessage = N'app_JobLoadFundStructures: ' + ERROR_MESSAGE()

            INSERT INTO [dbo].[ProcessorErrors]
            (Error, ContractId, Investor_id, PDate)
            VALUES (@ErrorMessage, @Contract_id, NULL, NULL);
        END CATCH

        fetch next from CntCur into @Contract_Id
    end
    close CntCur
    deallocate CntCur;
END
GO