namespace ReportsProcatt.Content
{
    public enum Currency
    {
        RUB,
        USD,
        EUR
    }
    public enum FilterOperationType
    {
        like,
        equals,
        more,
        less
    }
    public enum DuPositionType
    {
        Current,
        Closed
    }

    public enum DuPositionAssetTableName
    {
        Shares,
        Bonds,
        Bills,
        Cash,
        Fund,
        Derivatives
    }
}
